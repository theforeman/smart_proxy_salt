# Foreman Salt Report Upload

Currently, there are two possibilites to upload the salt report to Foreman:
1. Use /usr/sbin/upload-salt-reports which is called by a cron job every 10 minutes by default
2. Upload the report immediately by using a Salt Reactor.

This README, handles the second option and how to configure it

## Setup
Add the content of 'master.snippet' to '/etc/salt/master' which configures a reactor. 
In case there is already a reactor configured, you need to adapt it using the options mentioned in 'master.snippet'.

In case '/srv/salt' is configured as 'file_roots' in your '/etc/salt/master' config, setup the necessary salt state file and Salt runner functions:

```
/srv/salt/foreman_report_upload.sls
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

