---
id: bare_metal_install
title: NetSage Flow Processing Pipeline Installation Guide
sidebar_label: Server Installation Guide
---

This document covers installing the NetSage Flow Processing Pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives.

## Components

Minimum components

- Data Injestion Source (nfdump, tstat or both)
- RabbitMQ
- LogStash
- Importer (If you use nfdump)

## Prerequirements

The Processing pipeline needs data to injest in order to do anything. There are two types of data that are consumed.

1. nfdump (sflow or netflow)
2. tstat

You'll need to have at least one of them set up in order to be able to process the data.

### nfdump

The NetFlow Importer daemon works with nfdump. If you are only collecting tstat data, you do not need nfdump. nfdump is _not_ listed as a dependency of the Pipeline RPM package, as in a lot cases people are running special builds of nfdump -- but make sure you install it before you try running the Netflow Importer. If in doubt, `yum install nfdump` should work. Flow data exported by some routers require a newer version of nfdump than the one in the CentOS repos; in these cases, it may be necessary to manually compile and install the lastest nfdump.

Once nfdump is set up you'll need to configure your routers to send flow data to the running process that will save data to a particular location on disk.

### tstat

Tstat data should be sent directly to a rabbit queue (the same one that the Importer writes to, if it is used). From there, the data will be processed the same as sflow/netflow data.

## Installing the Prerequisites

### RabbitMQ

The pipeline requires a RabbitMQ server. Typically, this runs on the same server as the pipeline itself, but if need be, you can separate them (for this reason, the Rabbit server is not automatically installed with the pipeline package).

```sh
[root@host ~]# yum install rabbitmq-server

```

Typically, the default configuration will work. Perform any desired Rabbit configuration, if any. Then, start RabbitMQ:

```sh
[root@host ~]# /sbin/service rabbitmq-server start or # systemctl start rabbitmq-server.service
```

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

## Installing the Pipeline

Install it like this:

```
[root@host ~]# yum install grnoc-netsage-deidentifier
```

This will install Logstash and other dependencies. Make sure the number of logstash pipeline workers is set to 1 if you are using the aggregate filter!  (See note at bottom of this page.)  Start logstash, eg,

```sh
[root@host ~]# /sbin/service logstash start or # systemctl start logstash.service
```

Pipeline components:

1. Flow Filter - GlobalNOC uses this for Cenic data to filter out some flows. Not needed otherwise.
2. Netflow Importer - required to read nfcapd files from sflow and netflow importers. (If using tstat flow sensors only, this is not needed.)
3. Logstash configs - These are executed in alphabetical order. They read events from a rabbit queue, aggregate (i.e., stitch flows 
that were split between different nfcapd files), add information from geoIP and Science Registry databases, and write to a final rabbit queue.  The final rabbit queue is read by an independent logstash instance and events are put into elasticsearch. One could also modify the last logstash conf here to write to directly to elasticsearch.

Nothing will automatically start after installation as we need to move on to configuration. 


## Configuration

### Setting up the shared config file

The shared configuration files and logging configuration files are listed below (all of the pipeline components use these):

```
/etc/grnoc/netsage/deidentifier/netsage_shared.xml - Shared config file allowing configuration of collections, and Rabbit connection information
/etc/grnoc/netsage/deidentifier/logging.conf - logging config
/etc/grnoc/netsage/deidentifier/logging-debug.conf - logging config with debug enabled
```

The shared config file, used by all the non-logstash pipeline components, is read before reading the individual component config files [there used to be many perl-based components and daemons, though only the importer is left, the rest having been replaced by logstash].
This allowed one to easily configure values that applied to all stages, while allowing them to be overriden in the individual config files, if desired. A default shared config file is included: `/etc/grnoc/netsage/deidentifier/netsage_shared.xml`

The first, and most important, part of the configuration is the collection(s) this host will import. These are defined as follows:

```
<collection>
<!--    Top level directory of the nfcapd files for this sensor (within this dir are normally year directories, etc.) -->
     <flow-path>/path/to/flow-files/</flow-path>

<!--    Sensor name - can be the hostname or any string you like -->
     <sensor>hostname.tld</sensor>

<!--    Flow type - sflow or netflow (defaults to netflow) -->
    <flow-type>netflow</flow-type>

<!--    "instance" goes along with sensor.  This is to identify various instances if a sensor has -->
<!--    more than one "stream" / data collection.  Defaults to 0. -->
<!-- <instance>1</instance> -->

<!--    Defaults to sensor, but you can set it to something else here -->
<!-- <router-address></router-address> -->

</collection>
```

Note that `instance` and `router-address` can be left commented out. It's a good idea to set flow-type even if it is the default, just to be clear.

You can have multiple `collection` stanzas (each with its own <collection>...</collection>), to import from multiple sensors with one Importer process. You can also set up multiple Importers. Having multiple collections in one importer can sometimes cause issues for aggregation, as looping through the collections one at a time adds to the time between the matching flows it is looking for.

There is also RabbitMQ connection information in the shared config, but not the queue or channel, as these will vary per daemon. The Importer does not read from a rabbit queue but, eg, the flow filter daemon does, so both input and output are set. If you're running a default RabbitMQ config, which is open only to 'localhost' as guest/guest, you won't need to change anything here. Note that you will need to change the rabbit_output for the Finished Flow Mover Daemon regardless (see below).

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

Config file: `/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml`

Each stage [of the old perl pipeline] must be configured with Rabbit input and output queue information. The intention here is that flows should be deidentified before they leave the original node the flow data is collected on. If flows that have not be deidentified need to be pushed to another node for some reason, the Rabbit connection must be encrypted with SSL.

Notice that the only Rabbit connection information that's provided here is that which is not specific in the shared config file. This way if we need to change the credentials throughout the entire pipeline, it's easy to do. The Importer does not actually use any input rabbit queue,but we make a "fake" one as something is required here.

Note the name of the output queue, as it should match up to the logstash input queue name.  Keep num-processes ast 1. Set min-bytes to the threshold you want. This threshold is applied to flows aggregated within one nfcapd file. 

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

## Running the daemons

Typically, the daemons are started and stopped via init script (CentOS 6) or systemd (CentOS 7). They can also be run manually. The daemons all support these flags:

`--config [file]` - specify which config file to read

`--sharedconfig [file]` - specify which shared config file to read

`--logging [file]` - the logging config

`--nofork` - run in foreground (do not daemonize)

When run as a service, the Importer will have a deamon process and a worker process. When stopping the service, the worker process might take a few minutes to quit. If it does not quit, kill it by hand. 


## Logstash Setup Notes

Standard logstash filter config files are provided with this package. Most should be used as-is, but the input and output configs may be modified for your use.

The aggregation filter has settings that may be changed as well. Check the two timeouts and the aggregation maps path. 

When upgrading, these logstash configs will not be overwritten. Be sure any changes get copied into the production configs.

FOR FLOW STITCHING/AGGREGATION - IMPORTANT!
Flow stitching (ie, aggregation) will NOT work properly with more than ONE logstash pipeline worker!
Be sure to set "pipeline.workers: 1" in /etc/logstash/logstash.yml (default settingss) and/or /etc/logstash/pipelines.yml (settings take precedence). When running logstash on the command line, use "-w 1".

## Cron jobs

Sample cron files are provided. Please review and uncomment their contents. These periodically download MaxMind, CAIDA, and Science Registry files, and also restart logstash daily. Logstash needs to be restarted in order for any updated files to be read in. 



