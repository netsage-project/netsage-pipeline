---
id: docker_troubleshoot
title: Docker Troubleshooting
sidebar_label: Troubleshooting
---

### If you are not seeing flows 

- Be sure allow time for the first flows to timeout in the logstash aggregation - wait at least 10-15 minutes after starting up containers.
- Use `docker-compose ps` to see if all the containers are (still) running.
      (If there are no sflow/netflow sensors, the command should be "echo No Sflow/Netflow sensor" and the container state should be Exit 0.)

- Check the logs of the various containers to see if anything jumps out as being a problem.
- If logstash logs say things like *OutOfMemoryError: Java heap space* or *An unexpected connection driver error occured (Exception message: Connection reset)*  and the rabbit container is also down...  We've seen this before, but are not sure why it occurs. Try stopping everything, restarting docker for good measure, and starting all the containers up again. (If problems are continuing, it might be a memory issue.)
    ```
    docker-compose down
    sudo systemctl restart docker
    docker-compose up -d
    ```

- Check flow export on the network device to be sure it is (still) configured and running correctly.

- Make sure there really is traffic to be detected (with flows over 10 MB). A circuit outage or simple lack of large flows might be occurring.


## Problems most likely to occur at installation:

- Be sure conf-logstash/ files and dirs are readable by the logstash user (uid 1000, regardless of whether there is different username associated with uid 1000 on the host).  A logstash error about not being able to find *.conf files could be caused by a permissions problem.
- Files in logstash-downloads/ and conf-pmacct/ also need to be readable by the logstash user.
- Logstash-temp/ needs to be readable and also writable by the logstash user.

- Ensure routers are configured to send to the correct host and port and flow export is functioning.
- Check iptables on the pipeline host to be sure incoming traffic from the routers is allowed.
- Use tcpdump to be sure there are flows coming into the expected port.

- If the final rabbit queue is on a remote host, eg, at IU, check the credentials you are using and iptables on the remote host.

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


##Memory:
- If you are running a lot of data, sometimes docker may need to be allocated more memory. The most likely culprit is logstash (java) which is only allocated 4GB of RAM by default. Please see the Docker Advanced Options guide for how to change.

### If there are too few flows and flow sizes and rates are smaller than expected:

The router may not be sending the sampling rate with the flow data.
You may need to apply sampling corrections - see the Docker Advanced Options guide.

