"""
Salt runner to make generic https requests or perform directly
an autosign key removal.
"""


from http.client import HTTPSConnection
import ssl
import base64
import json
import logging
import yaml

FOREMAN_CONFIG = '/etc/salt/foreman.yaml'
log = logging.getLogger(__name__)


def salt_config():
    """
    Read the foreman configuratoin from FOREMAN_CONFIG
    """
    with open(FOREMAN_CONFIG) as config_file:
        config = yaml.safe_load(config_file.read())
    return config


def remove_key(minion):
    """
    Perform an HTTPS request to the configured foreman host and trigger
    the autosign key removal process.
    """
    config = salt_config()
    host_name = config[':host']
    port = config[':port']
    timeout = config[':timeout']
    method = 'PUT'
    path = '/salt/api/v2/salt_autosign_auth?name=%s' % minion

    # Differentiate between cert and user authentication
    if config[':proto'] == 'https':
        query_cert(host=host_name,
                   path=path,
                   port=port,
                   method=method,
                   cert=config[':ssl_cert'],
                   key=config[':ssl_key'],
                   timeout=timeout)
    else:
        query_user(host=host_name,
                   path=path,
                   port=port,
                   method=method,
                   username=config[':username'],
                   password=config[':password'],
                   timeout=timeout)


def query_cert(host, path, port, method, cert, key,
               payload=None, timeout=10):
    """
    Perform an HTTPS query with certificate credentials.
    """

    headers = {"Accept": "application/json"}

    if payload is not None or method.lower() in ['put', 'post']:
        headers["Content-Type"] = "application/json"

    ctx = ssl.create_default_context()
    ctx.load_cert_chain(certfile=cert, keyfile=key)

    connection = HTTPSConnection(host,
                                 port=port,
                                 context=ctx,
                                 timeout=timeout)
    if payload is None:
        connection.request(method,
                           path,
                           headers=headers)
    else:
        payload_json = json.dumps(payload)
        connection.request(method=method,
                           url=path,
                           body=payload_json,
                           headers=headers)
    response = connection.getresponse()
    response_str = response.read().decode('utf-8')
    print(response_str)


def query_user(host, path, port, method, username, password,
               payload=None, timeout=10):
    """
    Perform an HTTPS query with user credentials.
    """

    auth = "{}:{}".format(username, password)
    token = base64.b64encode(auth.encode('utf-8')).decode('ascii')
    headers = {"Authorization": "Basic {}".format(token),
               "Accept": "application/json"}
    if payload is not None or method.lower() in ["put", "post"]:
        headers["Content-Type"] = "application/json"

    ctx = ssl._create_unverified_context()
    connection = HTTPSConnection(host,
                                 port=port,
                                 context=ctx,
                                 timeout=timeout)
    if payload is None:
        connection.request(method=method,
                           url=path,
                           headers=headers)
    else:
        payload_json = json.dumps(payload)
        connection.request(method=method,
                           url=path,
                           body=payload_json,
                           headers=headers)
    response = connection.getresponse()
    response_str = response.read().decode('utf-8')
    print(response_str)
