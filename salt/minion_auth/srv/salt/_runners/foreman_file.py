#!/usr/bin/env python

import os
import time

SALT_KEY_PATH = "/etc/salt/pki/master/minions/"

def time_secs(path):
    stat = os.stat(path)
    return stat.st_mtime


def younger_than_secs(path, seconds):

    now_time = time.time()
    file_time = time_secs(path)
    if now_time - file_time <= seconds:
        return True
    return False

def check_key(hostname, seconds):
    return younger_than_secs(SALT_KEY_PATH + hostname, seconds)
