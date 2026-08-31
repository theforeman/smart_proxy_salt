"""
Salt ext_pillar module: load Foreman host parameters as pillar data.
"""

import logging
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


def _lookup(opts, minion_id):
    if requests is None or yaml is None:
        return {}
    cfg = (opts or {}).get('foreman') or {}
    s = requests.Session()
    if cfg.get('ssl_cert') and cfg.get('ssl_key'):
        s.cert = (cfg['ssl_cert'], cfg['ssl_key'])
    elif cfg.get('username') and cfg.get('password'):
        s.auth = (cfg['username'], cfg['password'])
    s.verify = cfg.get('ssl_ca', True)
    url = cfg.get('url', 'https://localhost').rstrip('/') \
          + '/salt/node/' + urllib.parse.quote(minion_id)
    try:
        r = s.get(url, params={'format': 'yml'},
                  headers={'Accept': 'application/x-yaml'},
                  timeout=cfg.get('timeout', 10))
        r.raise_for_status()
        return yaml.safe_load(r.text) or {}
    except Exception as exc:
        log.error("foreman _pillar: lookup for %s failed: %s", minion_id, exc)
        return {}


def ext_pillar(minion_id, _pillar, *_args, **_kwargs):
    master_opts = __opts__ if '__opts__' in globals() else {}
    enc = _lookup(master_opts, minion_id)
    return enc.get('parameters') or {}
