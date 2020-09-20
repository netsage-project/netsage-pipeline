---
id: docker_troubleshoot
title: Troubleshooting
sidebar_label: Troubleshooting
---

## Troubleshooting

### Data Flow issues:

**Troubleshooting checklist:**

- Make sure you configured your routers to point to the correct address/port where the collector is running.  hostname:9999 is the default.
- Make sure you created a .env file and updated the settings accordingly.
- sensorName especially since that identifies the source of the data.
- check the logs of the various components to see if anything jumps out as being invalid.  docker-compose logs -f <service_label>

### Resource Limitations

If you are running a lot of data sometimes docker may need to be allocated more memory. The most
likely culprit is logstash which is usually only allocated 1GB of RAM. You'll need to update the jvm.options file to grant it more memory.

Please see the [advaned section](/docs/deploy/docker_advanced#customize-logstash-settings) for details on how to customize logstash

Applying this snippet to logstash may help. Naturally the values will have to change.

You may also try the pattern below, if that still isn't enough.

```yaml
environment: + LS_JAVA_OPTS=-Xmx3g
```

Alternatively you may also try doing this:

```yaml
deploy:
  resources:
    limits:
      cpus: "0.50"
      memory: 50M
    reservations:
      cpus: "0.25"
      memory: 20M
```

Reference: https://docs.docker.com/compose/compose-file/#resources
