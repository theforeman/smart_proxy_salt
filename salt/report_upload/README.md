# Foreman Salt Report Upload

Currently, there are two possibilites to upload the salt report to Foreman:
1. Upload the report immediately by using a Salt Reactor (recommended).
2. Use /usr/sbin/upload-salt-reports manually (or set up a cronjob, see `/cron/smart_proxy_salt`).

This README handles the first option and how to configure it

## Setup
Add the content of 'master.snippet' to '/etc/salt/master' which configures a reactor. 
In case there is already a reactor configured, you need to adapt it using the options mentioned in 'master.snippet'.

Check the reactor file to be in the following folder (or a different one depending on your master configuration):

```
/var/lib/foreman-proxy/salt/reactors/foreman_report_upload.sls
```

In case '/srv/salt' is configured as 'file_roots' in your '/etc/salt/master' config, setup the necessary Salt runner:

```
/srv/salt/_runners/foreman_report_upload.py
```

After changing the salt master run:

```
systemctl restart salt-master
```

After adding the foreman_report_upload.sls and foreman_report_upload.py, run the following:

```
salt-run saltutil.sync_all
```

