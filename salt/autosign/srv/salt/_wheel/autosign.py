"""
Wheel module - Foreman's autosign entries on the master.

Used by smart_proxy_salt to add/remove autosign keys or hostnames.
Deploy and run: salt-run saltutil.sync_wheel
"""

import logging
import os
from contextlib import contextmanager

log = logging.getLogger(__name__)

__func_alias__ = {"list_": "list"}

DEFAULT_AUTOSIGN_FILE = "/etc/salt/autosign.conf"
DEFAULT_AUTOSIGN_KEY_FILE = "/var/lib/foreman-proxy/salt/grains/autosign_key"


def _autosign_file():
    return __opts__.get("autosign_file", DEFAULT_AUTOSIGN_FILE)


def _autosign_key_file():
    return __opts__.get("autosign_key_file", DEFAULT_AUTOSIGN_KEY_FILE)


@contextmanager
def _open_for_update(path):
    mode = "r+" if os.path.exists(path) else "w+"
    parent = os.path.dirname(path)
    if parent and not os.path.isdir(parent):
        os.makedirs(parent, mode=0o755)
    fh = open(path, mode)
    try:
        yield fh
    finally:
        fh.close()


def _append_value(path, value):
    try:
        with _open_for_update(path) as fh:
            content = fh.read()
            if value in content.splitlines():
                return True
            if content and not content.endswith("\n"):
                fh.write("\n")
            fh.write(value + "\n")
        log.info("autosign: added '%s' to %s", value, path)
        return True
    except (OSError, IOError) as exc:
        log.error("autosign: failed to add '%s' to %s: %s", value, path, exc)
        return False


def _remove_value(path, value):
    if not os.path.exists(path):
        return True
    try:
        with open(path, "r") as fh:
            lines = [line for line in fh if line.rstrip("\n") != value]
        with open(path, "w") as fh:
            fh.writelines(lines)
        log.info("autosign: removed '%s' from %s", value, path)
        return True
    except (OSError, IOError) as exc:
        log.error("autosign: failed to remove '%s' from %s: %s", value, path, exc)
        return False


def _list_values(path):
    if not os.path.exists(path):
        return []
    try:
        with open(path, "r") as fh:
            return [
                line.rstrip("\n")
                for line in fh
                if line.strip() and not line.lstrip().startswith("#")
            ]
    except (OSError, IOError) as exc:
        log.error("autosign: failed to read %s: %s", path, exc)
        return []


def add_hostname(hostname):
    return {"success": _append_value(_autosign_file(), hostname)}


def remove_hostname(hostname):
    return {"success": _remove_value(_autosign_file(), hostname)}


def add_key(key):
    return {"success": _append_value(_autosign_key_file(), key)}


def remove_key(key):
    return {"success": _remove_value(_autosign_key_file(), key)}


def list_():
    return _list_values(_autosign_file())
