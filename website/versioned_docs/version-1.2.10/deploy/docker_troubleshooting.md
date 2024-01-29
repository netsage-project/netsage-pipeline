---
id: docker_troubleshoot
title: Docker Troubleshooting
sidebar_label: Troubleshooting
---

## Troubleshooting

### If you are not seeing flows after installation

**Troubleshooting checklist:**

- Make sure you configured your routers to point to the correct address/port where the collector is running.  
- Check iptables on your pipeline host to be sure incoming traffic from the routers is allowed.
- Use `docker-compose ps` to be sure the collectors (and other containers) are running.
- Check to see if nfcapd files are being written. There should be a directory for the year, month, day and files should be larger than a few hundred bytes. If the files exist but are too small, the collector is running but there are no incoming flows.  "nfdump -r filename" will show the flows in a file.
- Make sure you created .env and docker-compose.override.yml files and updated the settings accordingly,  sensorName especially since that identifies the source of the data.
- Check the logs of the various containers to see if anything jumps out as being invalid.  `docker-compose logs -f $service_label`
- Check the logs to see if logstash is starting successfully. 
- If the final rabbit queue is on an external host, check iptables on that host to be sure incoming traffic from your pipeline host is allowed.

To see if flows are getting into and being read from the rabbit queue on the pipeline host, you can go to  `http://localhost:15672` in your favorite web browser. Login as guest with password guest. Look for accumulating messages and/or messages being acknowledged and published.

### If flow collection stops

**Logstash or Importer errors:**
- Make sure all containers are running.  `docker ps`
- Check the logs of the various containers to see if anything jumps out as being invalid.  `docker-compose logs -f $service_label`
- Check the logs to see if logstash is starting successfully.

**Disk space:**
- If the pipeline suddenly fails, check to see if the disk is full. If it is, first try getting rid of old docker images and containers to free up space: `docker image prune -a` and `docker container prune`.
- Also check to see how much space the nfcapd files are comsuming. You need to add more disk space. You could try saving fewer days of nfcapd files (see Docker Advanced). 

**Memory:**
- If you are running a lot of data, sometimes docker may need to be allocated more memory. The most
likely culprit is logstash which is usually only allocated 2GB of RAM. You'll need to update the jvm.options file to grant it more memory. 

Please see the [Docker Advanced guide](docker_install_advanced.md#customize-logstash-settings) for details on how to customize logstash.

Applying this snippet to logstash may help. For example, to give logstash (java) 3GB,

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

