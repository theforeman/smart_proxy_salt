"""
Config in __opts__['foreman']:
  url, ssl_ca, ssl_cert, ssl_key, username, password, timeout, cache_ttl
"""

import hashlib
import logging
import threading
import time
import urllib.parse

try:
    import requests
except ImportError:
    requests = None

try:
    import yaml
except ImportError:
    yaml = None

log = logging.getLogger(__name__)

DEFAULT_TIMEOUT = 10
DEFAULT_CACHE_TTL = 10

_CACHE = {}
_CACHE_LOCK = threading.Lock()


def _cfg():
    return (__opts__ or {}).get('foreman', {})


def is_cluster_owner(event_id):
    """
    Cluster-aware deduplication for reactor-triggered runners.
    """
    try:
        opts = __opts__ or {}
        if not opts.get('cluster_id'):
            return True
        me = opts.get('id')
        peers = sorted({me} | set(opts.get('cluster_peers') or []))
        if not peers or not me:
            return True
        idx = int(hashlib.md5(str(event_id).encode()).hexdigest(), 16) % len(peers)
        return peers[idx] == me
    except Exception as exc:
        log.warning("is_cluster_owner failed (%s), defaulting to owner", exc)
        return True


def _session():
    if requests is None:
        raise RuntimeError("foreman helpers need python3-requests")
    cfg = _cfg()
    s = requests.Session()
    if cfg.get('ssl_cert') and cfg.get('ssl_key'):
        s.cert = (cfg['ssl_cert'], cfg['ssl_key'])
    elif cfg.get('username') and cfg.get('password'):
        s.auth = (cfg['username'], cfg['password'])
    s.verify = cfg.get('ssl_ca', True)
    return s


def _url(path):
    return _cfg().get('url', 'https://localhost').rstrip('/') + path


def foreman_lookup(minion_id):
    """
    GET /salt/node/<minion> - returns Foreman's ENC payload.
    """
    if not minion_id:
        return {}

    cfg = _cfg()
    ttl = cfg.get('cache_ttl', DEFAULT_CACHE_TTL)
    now = time.monotonic()

    with _CACHE_LOCK:
        entry = _CACHE.get(minion_id)
        if entry and (now - entry['ts']) < ttl:
            return entry['data']

    try:
        resp = _session().get(_url('/salt/node/{}'.format(urllib.parse.quote(minion_id))),
                              params={'format': 'yml'},
                              headers={'Accept': 'application/x-yaml'},
                              timeout=cfg.get('timeout', DEFAULT_TIMEOUT))
        resp.raise_for_status()
        if yaml is None:
            raise RuntimeError("python3-pyyaml required to parse foreman ENC")
        data = yaml.safe_load(resp.text) or {}
    except Exception as exc:
        log.error("foreman: lookup for %s failed: %s", minion_id, exc)
        data = {'classes': [], 'parameters': {}}

    with _CACHE_LOCK:
        _CACHE[minion_id] = {'ts': now, 'data': data}
    return data


def foreman_notify_minion_auth(minion):
    """
    Foreman flips salt_status to minion_auth_success and tells the
    smart-proxy to delete the autosign key.
    """
    cfg = _cfg()
    try:
        resp = _session().put(_url('/salt/api/v2/salt_autosign_auth'),
                              params={'name': minion},
                              headers={'Accept': 'application/json',
                                       'Content-Type': 'application/json'},
                              timeout=cfg.get('timeout', DEFAULT_TIMEOUT))
        resp.raise_for_status()
        log.info("foreman: notified auth for %s", minion)
        return True
    except Exception as exc:
        log.error("foreman: notify_minion_auth %s failed: %s", minion, exc)
        return False


def foreman_post_job_report(report):
    """POST a highstate job report to /salt/api/v2/jobs/upload."""
    job_id = (report.get('job') or {}).get('job_id', '?')
    cfg = _cfg()
    try:
        resp = _session().post(_url('/salt/api/v2/jobs/upload'),
                               json=report,
                               headers={'Accept': 'application/json'},
                               timeout=cfg.get('timeout', DEFAULT_TIMEOUT))
        resp.raise_for_status()
        log.info("foreman: uploaded job report %s", job_id)
        return True
    except Exception as exc:
        log.error("foreman: upload_job_report %s failed: %s", job_id, exc)
        return False


def foreman_post_facts(minion, grains):
    """POST grains to /api/hosts/facts."""
    if not grains:
        log.warning("foreman: no grains for %s, skip upload", minion)
        return False

    cfg = _cfg()
    facts = {
        'name': minion,
        'facts': dict(grains,
                      _type='foreman_salt',
                      operatingsystem=grains.get('os'),
                      operatingsystemrelease=grains.get('osrelease')),
    }
    try:
        resp = _session().post(_url('/api/hosts/facts'),
                               json=facts,
                               headers={'Accept': 'application/json,version=2'},
                               timeout=cfg.get('timeout', DEFAULT_TIMEOUT))
        resp.raise_for_status()
        log.info("foreman: uploaded grains for %s", minion)
        return True
    except Exception as exc:
        log.error("foreman: upload_grains %s failed: %s", minion, exc)
        return False
