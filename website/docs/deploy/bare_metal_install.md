---
id: bare_metal_install
title: Manual Installation Guide
sidebar_label: Manual Installation 
---

This document covers installing and running the NetSage Flow Processing Pipeline manually (without using Docker). It assumes a RedHat Linux environment or one of its derivatives.

## Data sources

The Processing pipeline needs data to ingest in order to do anything. There are two types of data that can be consumed.

1. sflow or netflow
2. tstat

At least one of these must be set up on a sensor to provide the incoming flow data.

See the Docker Installation instuctions for more info.


## Installing the Prerequisites


### Installing Pmacct

The pmacct package provides nfacctd and sfacctd processes which receive flow data and write it to a rabbitmq queue.

Since the pmacct devs have not released a tagged version (or docker containers) since 1.7.7, and we require some commits that fixed an issue for us on Oct 11, 2021, we need to build pmacct from master (or master from some time after Oct 11, 2021).  

```
    1. Go to the host where you want to install or upgrade nfacctd and sfacctd
    2. Get dependencies if they were not previously installed on the host (Netsage needs librabbitmq-devel and jansson-devel)
         $ sudo yum install libpcap-devel  pkgconfig  libtool  autoconf  automake  make
         $ sudo yum install libstdc++-devel  gcc-c++  librabbitmq-devel  jansson-devel.x86_64
    3. Clone the repo
         $ git clone https://github.com/pmacct/pmacct.git
    4. Rename the dir to, eg, pmacct-02Jun2022/, using today's date or the date of the code you are going to check out. eg.
         $ cd pmacct-02June2022
    5. You should be in master at this point.
       To build and install a specific release/tag/branch, just check out that tag/branch and proceed.   
       We have done testing (and made docker images) with this version:
         $ git checkout 865a81e1f6c444aab32110a87d72005145fd6f74
    6. Get ready to build sfacctd and nfacctd   (the following options are needed for Netsage)
         $ ./autogen.sh
         $ ./configure --enable-rabbitmq --enable-jansson             
    7. Build and install
         $ make
         $ sudo make install 
         $ make clean
         $ make distclean
    8. Check the versions
         $ sfacctd -V
         $ nfacctd -V
       These should give something like this where 20220602 is the date:
            nfacctd 1.7.8-git [20220602-0 (5e4b0612)]
```


### Installing RabbitMQ

A local rabbitmq instance is used to hold flow data until logstash can retreive and process it. 

Typically, the rabbitmq server runs on the same server as the pipeline itself, but if need be, you can separate them (for this reason, the Rabbit server is not automatically installed with the pipeline package).

```sh
[root@host ~]# yum install rabbitmq-server

```

Typically, the default configuration will work. Perform any desired Rabbit configuration, then, start RabbitMQ:

```sh
[root@host ~]# /sbin/service rabbitmq-server start 
          or # systemctl start rabbitmq-server.service
```

Being able to view the user interface in a browser window is very useful. Look up how to enable it.

### Installing Logstash

See the logstash documentation. We are currently using Version 7.16.2.

```
Download and install the public signing key
        sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

Create or edit /etc/yum.repos.d/ELK.repo
        [logstash-7.x]
        name=Elastic repository for 7.x packages
        baseurl=https://artifacts.elastic.co/packages/7.x/yum
        gpgcheck=1
        gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
        enabled=1
        autorefresh=1
        type=rpm-md

Install
        sudo yum install logstash
``` 


### Installing the Pipeline 

Installing the Pipeline just copies config, cron, and systemd files to the correct locations. There are no longer any perl scripts to install.

The last Pipeline package released by GlobalNOC (**a non-pmacct version**) is in the GlobalNOC Open Source Repo. You can use that, if the version you want is there, or you can just build the rpm from scratch, or manually copy files to the correct locations (the .spec file indicates where).

(At least formerly, some of our dependencies come from the EPEL repo. We probably don't need this repo anymore though.)

a. To use the GlobalNOC Public repo, for Red Hat/CentOS 7, create `/etc/yum.repos.d/grnoc7.repo` with the following content.

```
[grnoc7]
name=GlobalNOC Public el7 Packages - $basearch
baseurl=https://repo-public.grnoc.iu.edu/repo/7/$basearch
enabled=1
gpgcheck=1
gpgkey=https://repo-public.grnoc.iu.edu/repo/RPM-GPG-KEY-GRNOC7
```

The first time you install packages from the repo, you will have to accept the GlobalNOC repo key.

Install the package using yum:

```
[root@host ~]# yum install grnoc-netsage-pipeline
```

b. To build the rpm from a git checkout, 

```
git clone https://github.com/netsage-project/netsage-pipeline.git
git checkout master  (or a branch)
cd netsage-pipeline
perl Makefile.PL
make rpm
sudo yum install /<path>/rpmbuild/RPMS/noarch/grnoc-netsage-pipeline-2.0.0-1.el7.noarch.rpm
     (use "reinstall" if the version number has not changed)
```

c. You could also just move files manually to where they need to go. It should be fairly obvious.
- /etc/logstash/conf.d/
- /etc/pmacct/
- /etc/cron.d/
- /usr/bin/
- /etc/systemd/system/
- /var/lib/grnoc/netsage/ and /etc/logstash/conf.d/support/  (cron downloads)

## Logstash Configuration Files 

We normally use defaults in Logstash settings files, but for Netsage, which uses the Logstash Aggregation filter, it is **required to use only ONE logstash pipeline worker**.

IMPORTANT:  Be sure to set `pipeline.workers: 1` in /etc/logstash/logstash.yml and/or /etc/logstash/pipelines.yml. When running logstash on the command line, use `-w 1`.

The Logstash config files containing the "filters" that comprise the Pipeline are installed in /etc/logstash/conf.d/. Most should be used as-is, but the input (01-) and output (99-) configs may be modified for your use.  The aggregation filter (40-) also has settings that may be changed - check the two timeouts and the aggregation maps path. 

> **When processing flows from multiple customers**
>
> - We use one logstash instance with multiple "logstash-pipelines". The logstash-pipelines are defined in /etc/logstash/pipelines.yml. 
> - Each logstash-pipeline uses config files in a different directory under /etc/logstash/pipelines/. 
> - Since most of the config files are the same for all logstash-pipelines, we use symlinks back to files in /etc/logstash/conf.d/.
> - The exceptions are the input, output, and aggregation files (01-, 99-, and 40-). These are customized so that each logstash-pipeline reads from a different rabbit queue, saves in-progress aggregations to a different file when logstash stops, and writes to a different rabbit queue after processing.
> - We normally use one input rabbit queue and logstash-pipeline per customer (where one customer may have multiple sensors), but if there are too many sensors, with too much data, we may split them up into 2 or 3 different input queues and pipelines.
> - The output rabbit queues for processed flows may be on a different host (for us, they are). There, additional independent logstash pipelines can grab the flows and stick them into elasticsearch. Various queues may connect to various ES indices. It's most convenient to put all flows from sensors that will show up in the same granfana portal together in one index (or set of dated indices). 

Check the 15-sensor-specific-changes.conf file. When running without Docker, especially with multiple customers, it's much easier to replace the contents of that file, which reference environment file values, with hard-coded "if" stagements and clauses that do just what you need.

ENV FILE: Our standard processing for Netsage uses the default values for environment variables. These are set directly in the logstash configs. If any of these need to be changed, you can use an environment file: `/etc/logstash/logstash-env-vars`. The systemd unit file for logstash is set to read this file if it exists.  You could copy into any or all the logstash-related settings from the env.example file. 

Note that this file will be read and used by all logstash-pipelines.


## Pmacct Configuration and Unit Files

Each sensor is assumed to send to a different port on the pipeline host, and each port must have a different collector listening for incoming flow data. With pmacct, these collectors are nfacctd and sfacctd processes. Each requires its own config files and systemd unit file. 

The easiest way to make the config files is to use the .env file and the setup-pmacct-compose.sh script that were primarily written for use with docker installations.  See the Docker Installation documentation for details.  
Doing just a few sensors at a time, edit the .env file and run the script. After running the script, you will find files like nfacctd_1.conf and nfacctd_1-pretag.map in conf-pmacct/ (in the git checkout). 

You will have to then make the following changes:
- Rename the newly created .conf and .map files, replacing _1 with _sensorName (some string that makes sense to humans).  Similarly of _2, etc.
- Edit each .conf file and change the name of the .map file within to match (the pre_tag_map value) 
- Also, in each .conf file
    - change the port number (nfacctd_port or sfacctd_port) to be the port to which the sensor is sending
    - change the rabbit host (amqp_host) from "rabbit" to "localhost"
    - change the name of the output rabbit queue (amqp_routing_key) to something unique (eg, netsage_deidentifier_raw_sensorName)
- Finally, copy the files to /etc/pmacct/ 
(You can have the script make some of these changes for you if you temporarily edit the conf-pmacct/*.ORIG files.) 

You will also need to create systemd unit files to start and stop each process. Use systemd/sfacctd.service and nfacctd.service as examples. Each should be given a name like nfacctd-sensorName.service. Within the files, edit the config filename in two places. 

 
## Start Logstash

```sh
# systemctl start logstash.service
```
It will take a minute or two to start. Log files are normally /var/log/messages and /var/log/logstash/logstash-plain.log. `sudo systemctl status logstash` is also handy.  

Be sure to check to see if it starts ok. If not, look for an error message. If all is ok, the last couple lines should be how many pipelines are running and something about connecting to rabbit.

NOTE: When logstash is stopped, any flows currently "in the aggregator" will be written out to /tmp/logstash-aggregation-maps (or the path/file set in 40-aggregation.conf). These will be read in and deleted when logstash is started again.  (In some situations, it is desirable to just delete those files before restarting.)

## Start Pmacct Processes

```sh
# systemctl start nfacctd-sensor1
# systemctl start sfacctd-sensor2
etc.
```

After starting these processes, it's good to check the rabbit UI to watch for incoming flow data. Netflow data usually comes in every minute, depending on router settings, and sflow data should come in every 5 minutes since we have set sfacctd to do some pre-aggregation and send results every 5 minutes. You should also see that the messages are consumed by logstash and there is no long-term accumulation of messages in the queue.

We have noted that in some cases, pmacct is providing so many flows that logstash cannot keep up and the number of messages in the queue just keeps increaseing! This is an issue that has yet to be resolved.

Flows should exit the pipeline (and appear in Elasticsearch) after about 15 minutes. The delay is due to aggregation. Long-lasting flows will take longer to exit.

## Cron jobs

Inactive cron files are installed (and provided in the cron.d/ directory of the git checkout). Baremetal-netsage-downloads.cron and restart-logstash-service.cron should be in /etc/cron.d/. Please review and uncomment their contents. 

These periodically download MaxMind, CAIDA, and Science Registry files, and also restart logstash. Logstash needs to be restarted in order for any updated files to be used.



