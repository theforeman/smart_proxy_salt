"""
Salt master_tops module: classify minions via Foreman's ENC endpoint.
"""

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

__virtualname__ = 'foreman'


def __virtual__():
    return __virtualname__


_CACHE = {}
_CACHE_LOCK = threading.Lock()


def _foreman_lookup(opts, minion_id):
    """ENC fetch"""
    if not minion_id:
        return {}
    cfg = (opts or {}).get('foreman') or {}
    ttl = cfg.get('cache_ttl', 10)
    now = time.monotonic()
    with _CACHE_LOCK:
        entry = _CACHE.get(minion_id)
        if entry and (now - entry['ts']) < ttl:
            return entry['data']

    data = {'classes': [], 'parameters': {}}
    if requests is None or yaml is None:
        log.error("foreman _tops: requests + pyyaml required")
        return data

    s = requests.Session()
    if cfg.get('ssl_cert') and cfg.get('ssl_key'):
        s.cert = (cfg['ssl_cert'], cfg['ssl_key'])
    elif cfg.get('username') and cfg.get('password'):
        s.auth = (cfg['username'], cfg['password'])
    s.verify = cfg.get('ssl_ca', True)
    url = cfg.get('url', 'https://localhost').rstrip('/') \
          + '/salt/node/' + urllib.parse.quote(minion_id)
    try:
        resp = s.get(url, params={'format': 'yml'},
                     headers={'Accept': 'application/x-yaml'},
                     timeout=cfg.get('timeout', 10))
        resp.raise_for_status()
        data = yaml.safe_load(resp.text) or data
    except Exception as exc:
        log.error("foreman _tops: lookup for %s failed: %s", minion_id, exc)

    with _CACHE_LOCK:
        _CACHE[minion_id] = {'ts': now, 'data': data}
    return data


def top(opts=None, **kwargs):
    minion_id = (opts or {}).get('id') or kwargs.get('id')
    if not minion_id:
        return {}
    master_opts = __opts__ if '__opts__' in globals() else (opts or {})
    enc = _foreman_lookup(master_opts, minion_id)
    classes = enc.get('classes') or []
    if not classes:
        return {}
    env = enc.get('environment') or 'base'
    return {env: list(classes)}
