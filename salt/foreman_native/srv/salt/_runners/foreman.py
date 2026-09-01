"""
Salt master runner: push minion grains/facts to Foreman.
"""

import fnmatch
import logging

log = logging.getLogger(__name__)

__virtualname__ = 'foreman'


def __virtual__():
    return __virtualname__


def upload_grains(minion=None):
    if not minion:
        log.error("foreman.upload_grains: no minion id provided")
        return False
    if not __utils__['foreman.is_cluster_owner'](minion):
        log.debug("foreman.upload_grains: not cluster owner for %s, skip", minion)
        return None

    grains = __salt__['cache.grains'](minion)

    if isinstance(grains, dict) and minion in grains and isinstance(grains[minion], dict):
        grains = grains[minion]
    return __utils__['foreman.foreman_post_facts'](minion, grains)


def remove_authenticated_key(minion=None):
    if not minion:
        log.error("foreman.remove_authenticated_key: no minion id provided")
        return False
    if not __utils__['foreman.is_cluster_owner'](minion):
        log.debug("foreman.remove_authenticated_key: not cluster owner for %s, skip", minion)
        return None

    grains = __salt__['cache.grains'](minion)
    # cache.grains may return either a flat dict or {<minion>: {...}}; unwrap.
    if isinstance(grains, dict) and minion in grains and isinstance(grains[minion], dict):
        grains = grains[minion]
    autosign_key = (grains or {}).get('autosign_key')
    if not autosign_key:
        log.warning("foreman: no autosign_key grain cached for %s; skipping cleanup", minion)
        return False

    result = __salt__['saltutil.wheel'](
        'autosign.remove_key', key=autosign_key,
    )
    success = bool(((result or {}).get('return') or {}).get('success'))
    log.info("foreman: autosign-key cleanup for %s (key=%s): %s",
             minion, str(autosign_key)[:8], "ok" if success else "failed")
    return success


def notify_authenticated(minion=None):
    if not minion:
        log.error("foreman.notify_authenticated: no minion id provided")
        return False
    if not __utils__['foreman.is_cluster_owner'](minion):
        log.debug("foreman.notify_authenticated: not cluster owner for %s, skip", minion)
        return None
    return __utils__['foreman.foreman_notify_minion_auth'](minion)


def upload_job_report(event_data=None):
    """
    Upload a state-job return to Foreman.
    """
    if not event_data:
        return False

    minion = event_data.get('id')
    if not minion:
        log.error("foreman.upload_job_report: event has no id")
        return False
    if not __utils__['foreman.is_cluster_owner'](minion):
        log.debug("foreman.upload_job_report: not cluster owner for %s, skip", minion)
        return None

    report = _extract_report(event_data)
    if report is None:
        log.debug("foreman.upload_job_report: fun=%s not in upload_states, skip",
                  event_data.get('fun'))
        return None

    return __utils__['foreman.foreman_post_job_report'](report)


def _upload_specs():
    """Return the list of upload-state specs ('fun' or 'fun arg-glob')."""
    cfg = (__opts__ or {}).get('foreman') or {}
    specs = cfg.get('upload_states') or ['state.highstate']
    return [str(s) for s in specs]


def _match_spec(fun, first_arg, specs):
    """True if (fun, first_arg) matches any spec. Spec = 'fun [arg-glob]'."""
    for spec in specs:
        parts = spec.split(None, 1)
        if fun != parts[0]:
            continue
        if len(parts) == 1:
            return True
        if first_arg is not None and fnmatch.fnmatchcase(str(first_arg), parts[1]):
            return True
    return False


def _extract_report(data):
    """
    Build {'job': {result, function, job_id}}. Direct match on fun + arg
    """
    fun = data.get('fun')
    jid = data.get('jid')
    mid = data.get('id')
    fun_args = data.get('fun_args') or []
    first_arg = fun_args[0] if fun_args else None

    if _match_spec(fun, first_arg, _upload_specs()):
        return {'job': {
            'result':   {mid: data.get('return')},
            'function': fun,
            'job_id':   jid,
        }}

    if fun == 'state.template_str':
        for key, entry in (data.get('return') or {}).items():
            if key.startswith('module_') and isinstance(entry, dict) \
                    and entry.get('__id__') == 'state.highstate':
                try:
                    inner = next(iter(entry['changes'].values()))
                except (KeyError, StopIteration):
                    return None
                return {'job': {
                    'result':   {mid: inner},
                    'function': 'state.highstate',
                    'job_id':   jid,
                }}

    return None
