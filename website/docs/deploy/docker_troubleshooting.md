---
id: docker_troubleshoot
title: Docker Troubleshooting
sidebar_label: Troubleshooting
---

## Troubleshooting

### If you are not seeing flows after installation

**Troubleshooting checklist:**

- Use `docker-compose ps` to be sure the collectors (and other containers) are running.
- Make sure you configured your routers to point to the correct address/port where the collector is running.  
- Check iptables on your pipeline host to be sure incoming traffic from the routers is allowed.
- Check to see if nfcapd files are being written. There should be a directory for the year, month, and day in netsage-pipeline/data/input_data/netflow/ or sflow/, and files should be larger than a few hundred bytes. If the files exist but are too small, the collector is running but there are no incoming flows.  "nfdump -r filename" will show the flows in a file (you may need to install nfdump).
- Make sure you created .env and docker-compose.override.yml files and updated the settings accordingly,  sensorName especially since that identifies the source of the data.
- Check the logs of the various containers to see if anything jumps out as being invalid.  `docker-compose logs $service`, where $service is logstash, importer, rabbit, etc.
- If the final rabbit queue is on an external host, check the credentials you are using and whether iptables on that host allows incoming traffic from your pipeline host.

### If flow collection stops

**Errors:**
- See if any of the containers has died using  `docker ps`
- Check the logs of the various containers to see if anything jumps out as being invalid. Eg, `docker-compose logs logstash`.
- If logstash dies with an error about not finding \*.conf files, make sure conf-logstash/ and directories and files within are readable by everyone (and directories are executable by everyone). The data/ directory and subdirectories need to be readable and writable by everyone, as well.

**Disk space:**
- If the pipeline suddenly fails, check to see if the disk is full. If it is, first try getting rid of old docker images and containers to free up space: `docker image prune -a` and `docker container prune`.
- Also check to see how much space the nfcapd files are consuming. You may need to add more disk space. You could also try automatically deleting nfcapd files after a fewer number of days (see Docker Advanced). 

**Memory:**
- If you are running a lot of data, sometimes docker may need to be allocated more memory. The most
likely culprit is logstash (java) which is only allocated 2GB of RAM by default. Please see the Docker Advanced guide for how to change.

