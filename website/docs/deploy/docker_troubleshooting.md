---
id: docker_troubleshoot
title: Docker Troubleshooting
sidebar_label: Troubleshooting
---

### If you are not seeing flows after installation

**Troubleshooting checklist:**

- Use `docker-compose ps` to be sure the all the containers are (still) running.
      (If there are no sflow/netflow sensors, the command should be "echo No Sflow/Netflow sensor" and the container state should be Exit 0.)
- Check the logs of the various containers to see if anything jumps out as being invalid.  
- Make sure you configured your routers to point to the correct host and port.
- Check iptables on your pipeline host to be sure incoming traffic from the routers is allowed.
- Use tcpdump to be sure there are flows coming into the expected port.
- If the final rabbit queue is on an external host, check the credentials you are using and whether iptables on that host allows incoming traffic from your pipeline host.
- Did you create and edit .env? 
    - Are the numbers of sensors, sensor names, and port numbers correct? 
    - Make sure you don't have sflows going to a nfacctd process or vise versa.
    - Are there names and port numbers for each sensor? 
    - Are the environment variable names for sensors like *_1, *_2, *_3, etc. with one sequence for sflow and one for netflow?
- Did you run setup-pmacct.sh?
- In docker-compose.override.yml, make sure the ports are set correctly. You will see *port on host : port in container*. (Docker uses its own port numbers internally.) *Port on host* should match what is in .env (the port the router is sending to on the pipeline host). *Port in container* should match what is in the corresponding pmacct config.  
- In pmacct config files, make sure amqp_host is set to rabbit (for docker installs) or localhost (for bare metal)
- In 'docker-compose ps' output, be sure the command for the sfacctd_1 container is /usr/local/sbin/sfacctd, similarly for nfacctd.
- In docker-compose.yml and docker-compose.override.yml, make sure "command:"s specify config files with the right _n's (these are actually just the parameters for the commands).

### If there are too few flows and flow sizes and rates are too low

The router may not be sending the sampling rate. This should show up as @sampling_corrected = no.
You may need to apply sampling corrections using an advanced logstash option.

### If flow collection stops

**Errors:**
- See if any of the containers has died using  `docker ps`
- Check the logs of the various containers to see if anything jumps out as being invalid. Eg, `docker-compose logs logstash`.
- If logstash logs say things like *OutOfMemoryError: Java heap space* or *An unexpected connection driver error occured (Exception message: Connection reset)*  and the rabbit container is also down...  We've seen this before, but are not sure why it occurs. Try stopped everything, restarting docker for good measure, and starting everything up again. (If problems are continuing, it might be a memory issue.)
    ```
    docker-compose down
    sudo systemctl restart docker
    docker-compose up -d
    ```
- If logstash dies with an error about not finding \*.conf files, make sure conf-logstash/, and directories and files within, are readable by everyone (and directories are executable by everyone). 
- logstash-downlaods/ and conf-pmacct/ files need to be readable.
- logstash-temp/ needs to be owned (readable and writable) by the logstash user (uid 1000, regardless of whether there is different username associated with uid 1000 on the host). 


**Memory:**
- If you are running a lot of data, sometimes docker may need to be allocated more memory. The most likely culprit is logstash (java) which is only allocated 4GB of RAM by default. Please see the Docker Advanced guide for how to change.

**Disk space:**
- If the pipeline suddenly fails, check to see if the disk is full. If it is, first try getting rid of old docker images and containers to free up space: `docker image prune -a` and `docker container prune`.


