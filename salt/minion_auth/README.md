# Foreman Salt Minion Authentication

Currently, there are two possibilites to authenticate a newly deployed minion automatically:
1. Use the _/etc/salt/autosign.conf_ file which stores the hostnames of acceptable hosts.
2. Use _Salt Autosign Grains_ for a more secure way which relies on a shared secret key.

This README, handles the second option and how to configure it

## Setup
Add the content of 'master.snippet' to '/etc/salt/master' which configures the grains key file on the master and a reactor. The grains file holds the acceptable keys and will be written by the Smart Proxy when a new minion is deployed. The reactor initiates an interaction with Foreman Salt if a new minion was authenticated successfully.
In case there is already a reactor configured, you need to adapt it using the options mentioned in 'master.snippet'. The directories given in 'master.snippet' are the default ones. In case you want your files in a different place, you have to change the paths accordingly.

If '/srv/salt' is configured as 'file_roots' in your '/etc/salt/master' config, setup the necessary Salt runners:

```
/srv/salt/_runners/foreman_file.py
/srv/salt/_runners/foreman_https.py
```

Check if the reactor ('foreman_minion_auth.sls') is at the appropriated location:

```
/var/lib/foreman-proxy/salt/reactors/foreman_minion_auth.sls
```

Restart the salt-master service:

```
systemctl restart salt-master
```

After checking the reactor and runners, run the following command to make them available in the Salt environment:

```
salt-run saltutil.sync_all
```

## Procedure

1. A new host, configured as Salt minion, is deployed with Foreman Salt.
2. Foreman Salt generates a unique key for that minion and distributes it via the Provisioning Template to the host and via an API call to the Smart Proxy.
3. The Smart Proxy makes the key available for the Salt Autosign Grains procedure by adding it to the previously defined file (by default: /var/lib/foreman-proxy/salt/grains/autosign_key).
4. The Salt minion is started and uses the configured Salt autosign grain for authentication to the Salt master.
5. The Salt master accepts the minion depending on the key and the corresponding auth reactor is triggered on the Salt master.
6. The Salt master initiates an API call to Foreman Salt which marks the corresponding host status as	_authenticated_.
7. Foreman Salt triggers an API call to Smart Proxy Salt which deletes the key from the acceptable keys list of the Salt master (since the minion was authenticated already and shall not be reused).

The minion was authenticated successfully.
