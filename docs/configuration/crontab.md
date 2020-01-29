## Crontab

A crontab is automatically installed in the Magento 2 environment.  By default,
this will run `bin/magento cron:run` every minute.

You can run additional jobs on the cron by editing your `.warden/warden-env.yml`
and adding a new service.

For this service, you will want to add the labels:

```dockerfile
labels:
  - cron.schedule=* * * * *
  - cron.group=${WARDEN_ENV_NAME}
```

* `cron.group` is required to run the cron job and the value must be equal to the Warden environment name.  The
 environment variable included in the above example will serve this purpose for default installs.
* `cron.schedule` is a string in [cron expression format](https://godoc.org/github.com/robfig/cron#hdr-CRON_Expression_Format)
