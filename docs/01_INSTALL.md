---
id: install
title: Installation Guide
sidebar_label: Installation Guide
---


NEED TO WORK ON THIS MORE

# NetSage Flow Processing Pipeline Install Guide

This document covers installing the NetSage Flow Processing Pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives.

## Installing the Prerequisites

The pipeline requires a RabbitMQ server. Typically, this runs on the same server as the pipeline itself, but if need be, you can separate them (for this reason, the Rabbit server is not automatically installed with the pipeline package).

```
[root@host ~]# yum install rabbitmq-server
````

Typically, the default configuration will work. Perform any desired Rabbit configuration, if any. Then, start RabbitMQ:

```
[root@host ~]# /sbin/service rabbitmq-server start or # systemctl start rabbitmq-server.service
```

## nfdump

The NetFlow Importer daemon requires nfdump. If you are only using tstat, you do not need nfdump. nfdump is *not* listed as a dependency of the Pipeline RPM package, as in a lot cases people are running special builds of nfdump -- but make sure you install it before you try running the Netflow Importer. If in doubt, `yum install nfdump` should work. Flow data exported by some routers require a newer version of nfdump than the one in the CentOS repos; in these cases, it may be necessary to manually compile and install the lastest nfdump.

## Installing the EPEL repo

Some of our dependencies come from the EPEL repo. To install this:

```
[root@host ~]# yum install epel-release
```

## Installing the GlobalNOC Open Source repo

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

## Installing the Pipeline

Pipeline components:
1. Flow Filter - GlobalNOC uses this for Cenic data as we do not want to process all of it. Not needed otherwise.
2. Netflow Importer - required to read nfcapd files from sflow and netflow importers. (If using tstat flow sensors, have them
send directly to the appropriate rabbit queue. 
3. Logstash configs - These are executed in alphabetical order. They read events from a rabbit queue, aggregate (ie stitch flows 
that were split between different nfcapd files), add information from geoIP and Science Registry data, and write to a final rabbit queue.
The final rabbit queue is read by an independent logstash instance and events are put into elasticsearch. One could also modify the
last logstash conf here to write to elasticsearch.

Nothing will automatically start after installation as we need to move on to configuration. Install it like this:

```
[root@host ~]# yum install grnoc-netsage-deidentifier
```

## Setting up the shared config file

Theshared config file, used by all the non-logstash pipeline components, is read before reading the individual config files [THERE USED TO BE MANY DAEMONS INSTEAD OF LOGSTASH. We should redo this]. This allows you to easily configure values that apply to all stages, while allowing you to override them in the individual config files, if desired. A default shared config file is included: `/etc/grnoc/netsage/deidentifier/netsage_shared.xml`

The first, and most important, part of the configuration is the collection(s) this host will import. These are defined as follows:
```
<collection>
    <flow-path>/path/to/flow-files</flow-path>
    <sensor>hostname.tld</sensor>
<!--  "instance" goes along with sensor
       This is to identify various instances if a sensor has more than one "stream" / data collection
       Defaults to 0.
    <instance>1</instance>
-->
  <!--
       Defaults to sensor, but you can set it to something else here
      <router-address></router-address>
  -->
 <!--
    Flow type: type of flow data (defaults to netflow)
 -->
 <!--
    <flow-type>sflow</flow-type>
 -->
</collection>
```

Notice that `instance`, `router-address`, and `flow-type` are commented out. You only need these if you need an something other than the default values, as described in the comments in the default shared config file.

You can have multiple `collection` stanzas, to import multiple collections on one host.

The shared config looks like this. Note that RabbitMQ connection information is listed, but not the queue or channel, as these will vary per daemon. If you're running a default RabbitMQ config, which is open only to 'localhost' as guest/guest, you won't need to change anything here. Note that you will need to change the rabbit_output for the Finished Flow Mover Daemon regardless (see below).

```
<config>
  <collection>
    <flow-path>/path/to/flow-files1</flow-path>
    <sensor>hostname1.tld</sensor>
  </collection>
  <collection>
    <flow-path>/path/to/flow-files2</flow-path>
    <sensor>hostname2.tld</sensor>
  </collection>

  <!-- rabbitmq connection info -->
  <rabbit_input>
    <host>127.0.0.1</host>
    <port>5671</port>
    <username>guest</username>
    <password>guest</password>
    <batch_size>100</batch_size>
    <vhost>netsage</vhost>
    <ssl>0</ssl>
    <cacert>/path/to/cert.crt</cacert> <!-- required if ssl is 1 -->
  </rabbit_input>

  <!-- The cache does not output to a rabbit queue (shared memory instead) but we still need something here -->
  <rabbit_output>
    <host>127.0.0.1</host>
    <port>5671</port>
    <username>guest</username>
    <password>guest</password>
    <batch_size>100</batch_size>
    <vhost>netsage</vhost>
    <ssl>0</ssl>
    <cacert>/path/to/cert.crt</cacert> <!-- required if ssl is 1 -->
  </rabbit_output>
</config>
```

## Configuring the Pipeline Stages

Each stage must be configured with Rabbit input and output queue information. The intention here is that flows should be deidentified before they leave the original node the flow data is collected on. If flows that have not be deidentified need to be pushed to another node for some reason, the Rabbit connection must be encrypted with SSL.

The username/password are both set to "guest" by default, as this is the default provided by RabbitMQ. This works fine if the localhost is processing all the data. The configs look something like this (some have additional sections).

Notice that the only Rabbit connection information that's provided here is that which is not specific in the shared config file. This way if we need to change the credentials throughout the entire pipeline, it's easy to do.

```xml
   <config>
     <!-- rabbitmq connection info -->
     <rabbit_input>
       <queue>netsage_deidentifier_raw</queue>
       <channel>2</channel>
     </rabbit_input>
   
     <!-- The cache does not output to a rabbit queue (shared memory instead) but we still need something here -->
     <rabbit_output>
       <queue>netsage_deidentifier_cached</queue>
       <channel>3</channel>
     </rabbit_output>
     <worker>
         <!-- How many concurrent workers should perform the necessary operations -->
         <!-- for stitching, we can only use 1 -->
       <num-processes>1</num-processes>
   
       <!-- where should we write the cache worker pid file to -->
       <pid-file>/var/run/netsage-cache-workers.pid</pid-file>
   
     </worker>
   </config>
```

The defaults should work unless the pipeline stages need to be reordered for some reason, or if SSL or different hosts/credentials are needed. However, the very endpoints should be checked. At the moment that means the flow cache (which is the first stage in the pipeline) and the flow mover (the last stage).

### Shared config file listing

The shared configuration files and logging configuration files are listed below (all of the pipeline components use these):

```
/etc/grnoc/netsage/deidentifier/netsage_shared.xml - Shared config file allowing configuration of collections, and Rabbit connection information
/etc/grnoc/netsage/deidentifier/logging.conf - logging config
/etc/grnoc/netsage/deidentifier/logging-debug.conf - logging config with debug enabled
```

## Running the daemons

Typically, the daemons are started and stopped via init script (CentOS 6) or systemd (CentOS 7). They can also be run manually. The daemons all support these flags:

`--config [file]` - specify which config file to read

`--sharedconfig [file]` - specify which shared config file to read

`--logging [file]` - the logging config

`--nofork` - run in foreground (do not daemonize)

For more details on each individual daemon, use the `--help` flag.

### Daemon Listing

#### netsage-netflow-importer-daemon
This is a daemon that reads raw netflow data, reads it, and pushes it to a Rabbit queue for processing.

Config file: `/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml`



# setup notes

INPUT AND OUTPUT LOGSTASH FILTERS
Standard logstash filter config files are provided with this package. Most should be used as-is, but the input and output configs (01-inputs.conf and 99-outputs.conf) may be modified for your use.
To use the provided 01-inputs.conf and 99-outputs.conf versions, fill in the IP of the final rabbit host in 99-outputs.conf, and put the rabbitmq usernames and passwords into the logstash keystore.
Your 01 and 99 conf files should not be overwritten by upgrades.

To set up the keystore:  (note that logstash-keystore takes a minute to come back with a prompt)
  Be sure /usr/share/logstash/config exists
  (the full path, in case you need it: /usr/share/logstash/bin/logstash-keystore)
  Create logstash.keystore in /etc/logstash/: (use the same directory as logstash.yml)

```sh
  $ sudo -E logstash-keystore --path.settings /etc/logstash/ create
    You can set a password for the keystore itself if you want to investigate that; otherwise skip it.
  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_input_username     (enter username when prompted)
  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_input_pw           (enter password when prompted)
  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_output_username    (enter username when prompted)
  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_output_pw          (enter password when prompted)
```sh
To list the keys:
```
  $ sudo -E logstash-keystore list

```sh
To remove a key-value pair:

```sh
  $ sudo -E logstash-keystore remove <key name>
```


FLOW STITCHING - IMPORTANT!
Flow stitching (ie, aggregation) will NOT work properly with more than ONE logstash pipeline worker!
Be sure to set "pipeline.workers: 1" in /etc/logstash/logstash.yml (default settingss) and/or /etc/logstash/pipelines.yml (settings take precedence). When running logstash on the command line, use "-w 1".

See the comments in 04-stitching.conf to learn more about how complete flows are defined.

