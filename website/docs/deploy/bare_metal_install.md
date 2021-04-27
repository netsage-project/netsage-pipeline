---
id: bare_metal_install
title: Manual Installation Guide
sidebar_label: Manual Installation 
---

This document covers installing the NetSage Flow Processing Pipeline manually on a new machine (without using Docker). Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives.

## Data sources

The Processing pipeline needs data to ingest in order to do anything. There are two types of data that can be consumed.

1. sflow or netflow
2. tstat

At least one of these must be set up on a sensor to provide the incoming flow data.

Sflow and netflow data should be sent to ports on the pipeline host where nfcapd and/or sfcapd are ready to receive it.

Tstat data should be sent directly to the logstash input RabbitMQ queue (the same one that the Importer writes to, if it is used). From there, the data will be processed the same as sflow/netflow data.

## Installing the Prerequisites

### Installing nfdump

The nfdump package provides nfcapd and sfcapd processes which recieve flow data and write nfcapd files. 
The Importer also uses nfdump. If you are only collecting tstat data, you do not need nfdump. 


Nfdump is _not_ listed as a dependency of the Pipeline RPM package, as in a lot cases people are running special builds of nfdump -- but make sure you install it before you try running the Netflow Importer. If in doubt, `yum install nfdump` should work. 
Flow data exported by some routers require a newer version of nfdump than the one in the CentOS repos; in these cases, it may be necessary to manually compile and install the lastest nfdump. 

:::note
It is recommended to check the version of nfdump used in the Docker installation and use the same or newer in order to be sure that any fixes for impactful issues are included.
:::


If desired, you can also install nfsen, which has a UI for viewing flow data and can manage starting and stopping all the nfcapd/sfcapd processes for you.The nfsen.conf file has a section in which to configure all the sources. 

### Installing RabbitMQ

The pipeline requires a RabbitMQ server. Typically, this runs on the same server as the pipeline itself, but if need be, you can separate them (for this reason, the Rabbit server is not automatically installed with the pipeline package).

```sh
[root@host ~]# yum install rabbitmq-server

```

Typically, the default configuration will work. Perform any desired Rabbit configuration, then, start RabbitMQ:

```sh
[root@host ~]# /sbin/service rabbitmq-server start 
          or # systemctl start rabbitmq-server.service
```

### Installing Logstash

See the logstash documentation. We are currently using Version 7.10.

### Installing the EPEL repo

Some of our dependencies come from the EPEL repo. To install this:

```
[root@host ~]# yum install epel-release
```

### Installing the GlobalNOC Open Source repo

The Pipeline package (and its dependencies that are not in EPEL) are in the GlobalNOC Open Source Repo.

For Red Hat/CentOS 6, create `/etc/yum.repos.d/grnoc6.repo` with the following content.

```
[grnoc6]
name=GlobalNOC Public el6 Packages - $basearch
baseurl=https://repo-public.grnoc.iu.edu/repo/6/$basearch
enabled=1
gpgcheck=1
gpgkey=https://repo-public.grnoc.iu.edu/repo/RPM-GPG-KEY-GRNOC6
```

For Red Hat/CentOS 7, create `/etc/yum.repos.d/grnoc7.repo` with the following content.

```
[grnoc7]
name=GlobalNOC Public el7 Packages - $basearch
baseurl=https://repo-public.grnoc.iu.edu/repo/7/$basearch
enabled=1
gpgcheck=1
gpgkey=https://repo-public.grnoc.iu.edu/repo/RPM-GPG-KEY-GRNOC7
```

The first time you install packages from the repo, you will have to accept the GlobalNOC repo key.

## Installing the Pipeline (Importer and Logstash configs)

Install it like this:

```
[root@host ~]# yum install grnoc-netsage-deidentifier
```

Pipeline components:

1. Flow Filter - GlobalNOC uses this for Cenic data to filter out some flows. Not needed otherwise.
2. Netsage Netflow Importer - required to read nfcapd files from sflow and netflow importers. (If using tstat flow sensors only, this is not needed.)
3. Logstash - be sure the number of logstash pipeline workers in /etc/logstash/logstash.yml is set to 1 or flow stitching/aggregation will not work right!  
4. Logstash configs - these are executed in alphabetical order.  See the Logstash doc. At a minimum, the input, output, and aggregation configs have parameters that you will need to update or confirm.

Nothing will automatically start after installation as we need to move on to configuration. 

## Importer Configuration

Configuration files of interest are
 - /etc/grnoc/netsage/deidentifier/netsage_shared.xml - Shared config file allowing configuration of collections, and Rabbit connection information
 - /etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml - other settings
 - /etc/grnoc/netsage/deidentifier/logging.conf - logging config
 - /etc/grnoc/netsage/deidentifier/logging-debug.conf - logging config with debug enabled

### Setting up the shared config file

`/etc/grnoc/netsage/deidentifier/netsage_shared.xml`

There used to be many perl-based pipeline components and daemons. At this point, only the importer is left, the rest having been replaced by logstash.  The shared config file, which was formerly used by all the perl components, is read before reading the individual importer config file.

The most important part of the shared configuration file is the definition of collections. Each sflow or netflow sensor will have its own collection stanza. Here is one such stanza, a netflow example. Instance and router-address can be left commented out.

```
<collection>
     <!-- Top level directory of the nfcapd files for this sensor (within this dir are normally year directories, etc.) -->
         <flow-path>/path/to/netflow-files/</flow-path>

     <!-- Sensor name - can be the hostname or any string you like. Shows up in grafana dashboards.  -->
         <sensor>Netflow Sensor 1</sensor>

     <!-- Flow type - sflow or netflow (defaults to netflow) -->
         <flow-type>sflow</flow-type>

     <!-- "instance" goes along with sensor.  This is to identify various instances if a sensor has -->
     <!-- more than one "stream" / data collection.  Defaults to 0. -->
     <!-- <instance>1</instance> -->

     <!-- Used in Flow-Filter. Defaults to sensor, but you can set it to something else here -->
     <!-- <router-address></router-address> -->
</collection>
```

Having multiple collections in one importer can sometimes cause issues for aggregation, as looping through the collections one at a time adds to the time between the flows, affecting timeouts. You can also set up multiple Importers with differently named shared and importer config files and separate init.d files. 

There is also RabbitMQ connection information in the shared config, though queue names are set in the Importer config. (The Importer does not read from a rabbit queue, but other old components did, so both input and output are set.) 

Ideally, flows should be deidentified before they leave the host on which the data is stored. If flows that have not be deidentified need to be pushed to another node for some reason, the Rabbit connection must be encrypted with SSL.

If you're running a default RabbitMQ config, which is open only to 'localhost' as guest/guest, you won't need to change anything here.

```
  <!-- rabbitmq connection info -->
  <rabbit_input>
    <host>127.0.0.1</host>
    <port>5672</port>
    <username>guest</username>
    <password>guest</password>
    <ssl>0</ssl>
    <batch_size>100</batch_size>
    <vhost>/</vhost>
    <durable>1</durable> <!-- Whether the rabbit queue is 'durable' (don't change this unless you have a reason) -->
  </rabbit_input>

  <rabbit_output>
    <host>127.0.0.1</host>
    <port>5672</port>
    <username>guest</username>
    <password>guest</password>
    <ssl>0</ssl>
    <batch_size>100</batch_size>
    <vhost>/</vhost>
    <durable>1</durable> <!-- Whether the rabbit queue is 'durable' (don't change this unless you have a reason) -->
  </rabbit_output>
```

### Setting up the Importer config file

`/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml`

This file has a few more setting specific to the Importer component which you may like to adjust.  

 - Rabbit_output has the name of the output queue. This should be the same as that of the logstash input queue.  
 - (The Importer does not actually use an input rabbit queue, so we add a "fake" one here.)
 - Min-bytes is a threshold applied to flows aggregated within one nfcapd file. Flows smaller than this will be discarded.
 - Min-file-age is used to be sure files are complete before being read. 
 - Cull-enable and cull-ttl can be used to have nfcapd files older than some number of days automatically deleted. 
 - Pid-file is where the pid file should be written. Be sure this matches what is used in the init.d file.
 - Keep num-processes set to 1.

```xml
<config>
  <!--  NOTE: Values here override those in the shared config -->

  <!-- rabbitmq queues -->
  <rabbit_input>
    <queue>netsage_deidentifier_netflow_fake</queue>
    <channel>2</channel>
  </rabbit_input>

  <rabbit_output>
    <channel>3</channel>
    <queue>netsage_deidentifier_raw</queue>
  </rabbit_output>

  <worker>
    <!-- How many flows to process at once -->
        <flow-batch-size>100</flow-batch-size>

    <!-- How many concurrent workers should perform the necessary operations -->
        <num-processes>1</num-processes>

    <!-- path to nfdump executable (defaults to /usr/bin/nfdump) -->
    <!--   <nfdump-path>/path/to/nfdump</nfdump-path>  -->

    <!-- Where to store the cache, where it tracks what files it has/hasn't read -->
        <cache-file>/var/cache/netsage/netflow_importer.cache</cache-file>

    <!-- The minium flow size threshold - will not  import any flows smaller than this -->
    <!-- Defaults to 500M  -->
        <min-bytes>100000000</min-bytes> 

    <!-- Do not import nfcapd files younger than min-file-age
        The value must match /^(\d+)([DWMYhms])$/ where D, W, M, Y, h, m and s are
        "day(s)", "week(s)", "month(s)", "year(s)", "hour(s)", "minute(s)" and "second(s)", respectively"
        See http://search.cpan.org/~pfig/File-Find-Rule-Age-0.2/lib/File/Find/Rule/Age.pm
        Default: 0 (no minimum age) 
    -->
        <min-file-age>10m</min-file-age> 

    <!-- cull-enable: whether to cull processed flow data files -->
    <!-- default: no culling; set to 1 to turn culling on -->
    <!--    <cull-enable>1</cull-enable>  -->

    <!-- cull-tty: cull time to live, in days -->
    <!-- number of days to retain imported data files before deleting them; default: 3 -->
    <!--    <cull-ttl>5</cull-ttl>  -->
  </worker>

  <master>
    <!-- where should we write the daemon pid file to -->
        <pid-file>/var/run/netsage-netflow-importer-daemon.pid</pid-file>
  </master>

</config>
```

## Logstash Setup Notes

Standard logstash filter config files are provided with this package. Most should be used as-is, but the input and output configs may be modified for your use.

The aggregation filter also has settings that may be changed as well - check the two timeouts and the aggregation maps path. 

When upgrading, these logstash configs will not be overwritten. Be sure any changes get copied into the production configs.

FOR FLOW STITCHING/AGGREGATION - IMPORTANT!
Flow stitching (ie, aggregation) will NOT work properly with more than ONE logstash pipeline worker!
Be sure to set "pipeline.workers: 1" in /etc/logstash/logstash.yml and/or /etc/logstash/pipelines.yml. When running logstash on the command line, use "-w 1".

## Start Logstash

```sh
[root@host ~]# /sbin/service logstash start 
          or # systemctl start logstash.service
```
It will take couple minutes to start. Log files are normally /var/log/messages and /var/log/logstash/logstash-plain.log.

When logstash is stopped, any flows currently "in the aggregator" will be written out to /tmp/logstash-aggregation-maps (or the path/file set in 40-aggregation.conf). These will be read in and deleted when logstash is started again. 

## Start the Importer

Typically, the daemons are started and stopped via init script (CentOS 6) or systemd (CentOS 7). They can also be run manually. The daemons all support these flags:

`--config [file]` - specify which config file to read

`--sharedconfig [file]` - specify which shared config file to read

`--logging [file]` - the logging config

`--nofork` - run in foreground (do not daemonize)

```sh
[root@host ~]# /sbin/service netsage-netflow-importer start 
          or # systemctl start netsage-netflow-importer.service
```
The Importer will create a deamon process and a worker process. When stopping the service, the worker process might take a few minutes to quit. If it does not quit, kill it by hand. 


## Cron jobs

Sample cron files are provided. Please review and uncomment their contents. These periodically download MaxMind, CAIDA, and Science Registry files, and also restart logstash. Logstash needs to be restarted in order for any updated files to be read in. 



