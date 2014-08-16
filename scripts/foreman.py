#!/usr/bin/env python
'''
Foreman returner for Salt minions.  Returners are placed in
/srv/salt/_returners and used as a way to send results from minions to a
third-party source.  This returner will use the Foreman Smart Proxy API to
deliver grains and highstate reports.

TODO: Sign reports with minions RSA key.
'''

import json
import yaml
import urllib2
from datetime import datetime
from itertools import chain

SALT_CONFIG = "/etc/salt/minion"

SALT_PROXY_PROTO = 'http'
SALT_PROXY_PORT = 8000


def returner(ret):
    """
    Return results to Foreman Smart Proxy
    """

    def array_to_dict(array):
        return dict([(str(index), value) for (index, value) in enumerate(array)])

    def flatten(array):
        for item in array:
            if isinstance(item, list):
                for nested_item in flatten(item):
                    yield nested_item
            else:
                yield item

    def foreman_send(report):
    	request = urllib2.Request(report_url())
	request.add_header('Content-Type', 'application/json')
        urllib2.urlopen(request, json.dumps(report))
        with open('/tmp/salt', 'w') as file:
	    file.write(json.dumps(report))

    def get_key(key, prefix):
        return "::".join([item for item in [prefix, key] if item is not None])

    def normalize_grains(name):
      """
      Unnests grains and makes otherwise compatible with Foreman fact importer
      """

      facts = __salt__['grains.items']()

      facts["operatingsystem"] = facts["os"]
      facts["operatingsystemrelease"] = facts["osrelease"]
      facts["_timestamp"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")
      facts["_type"] = "foreman_salt"

      grains = { "name": name,
                 "facts": {} }

      [grains["facts"].update(x) for x in flatten(plainify(facts))]

      return grains

    def plainify(hash, prefix = None):
        result = []
        for key, value in hash.iteritems():
            if isinstance(value, dict):
                result.append(plainify(value, get_key(key, prefix)))
            elif isinstance(value, list):
                result.append(plainify(array_to_dict(value), get_key(key, prefix)))
            else:
                new = {}
                new[get_key(key, prefix)] = value
                result.append(new)
        return result

    def report_url():
        config = yaml.load(open(SALT_CONFIG, 'r'))
        if config.has_key('master'):
            master = config['master']
        else:
            raise AttributeError("Unable to find salt master!")

        return "%s://%s:%d/salt/returner/%s" % (SALT_PROXY_PROTO, master, SALT_PROXY_PORT, ret['id'])


    report = { 'function': ret['fun'],
               'grains': normalize_grains(ret['id']),
               'pillar': __salt__['pillar.raw'](),
               'message': ret }

    foreman_send(report)

