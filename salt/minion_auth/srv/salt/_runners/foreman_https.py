#!/usr/bin/env python

from http.client import HTTPSConnection
import ssl
import base64
import json


def query_cert(host, path, port, method, cert, key,
               payload=None, timeout=10):

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
