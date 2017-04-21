# NetSage Deidentifier Install Guide

This document covers installing the NetSage deidentification pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives.

## Installing the Prerequisites

The pipeline requires a RabbitMQ server. Typically, this runs on the same server as the pipeline itself, but if need be, you can separate them (for this reason, the Rabbit server is not automatically installed with the pipeline package).

```
[root@host ~]# yum install rabbitmq-server
````

Typically, the default configuration will work. Perform any desired Rabbit configuration, if any. Then, start RabbitMQ:

```
[root@host ~]# /sbin/service rabbitmq-server start
```

The NetFlow Importer daemon requires nfdump. This is *not* listed as a dependency as in a lot cases people are running special builds of it -- but make sure you install it before you try running the Netflow Importer. If in doubt, `yum install nfdump` should work.

## Installing the Pipeline

The pipeline consists of several daemons, most of which read data from a Rabbit queue, perform some operations, and then push the results to another queue for further processing. Typically, they are run in this order:

0. Netflow Importer (optional - sometimes TSTAT TRANSPORT is used instead)
1. Flow Cache - takes raw flows and caches them in shared memory for the stitcher to process
2. Flow Stitcher - stitches flows spanning the 1-minute boundaries
3. Flow Tagger - Tags flows with GeoIP/ASN/Organization information
4. Flow Deidentifer - Deidentifies flow by stripping bits from the IP addresses (configurable)
5. Flow Mover - Moves finished flows to a queue for ingestion by TSDS (though actually this can generally be used to move flows from one queue to another)

The daemons are all contained within one package. Nothing will automatically start after installation as we need to move on to configuration. Install it like this:

```
[root@host ~]# yum install grnoc-netsage-deidentifier
```

## Configuring the Pipeline Stages

Each stage must be configured with Rabbit input and output queue information. The intention here is that flows should be deidentified before they leave the original node the flow data is collected on. If flows that have not be deidentified need to be pushed to another node for some reason, the Rabbit connection must be encrypted with SSL.

The username/password are both set to "guest" by default, as this is the default provided by RabbitMQ. This works fine if the localhost is processing all the data. The configs look something like this (some have additional sections).

```
<config>
  <!-- rabbitmq connection info -->
  <rabbit_input>
    <host>127.0.0.1</host>
    <port>5671</port>
    <username>guest</username>
    <password>guest</password>
    <batch_size>100</batch_size>
    <vhost>netsage</vhost>
    <queue>netsage_deidentifier_raw</queue>
    <channel>2</channel>
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
    <queue>netsage_deidentifier_cached</queue>
    <channel>3</channel>
    <ssl>0</ssl>
    <cacert>/path/to/cert.crt</cacert> <!-- required if ssl is 1 -->
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

### Configuring the first stage

As you can see above, by default, the Flow Cacher expects to find raw flows in a Rabbit queue in the netsage vhost called "netsage_deidentifier_raw". Have any flow collectors push raw flows here, or point this somewhere else if desired.

### Configuring the last stage

The rabbit output queue for last stage must be configured; currently this is the Flow Mover. It should be set to a queue from which TSDS writers read. From there, the data will be directly ingested by TSDS.


### Config file listing

The configuration files and logging configuration files are listed below:

```
/etc/grnoc/netsage/deidentifier/logging.conf
/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
/etc/grnoc/netsage/deidentifier/netsage_flow_cache.xml
/etc/grnoc/netsage/deidentifier/netsage_flow_stitcher.xml
/etc/grnoc/netsage/deidentifier/netsage_tagger.xml
/etc/grnoc/netsage/deidentifier/netsage_deidentifier.xml
/etc/grnoc/netsage/deidentifier/netsage_finished_flow_mover.xml
```

### Daemon Listing

#### netsage-netflow-importer-daemon
This is a daemon that reads raw netflow data, reads it, and pushes it to a Rabbit queue for processing.

#### netsage-flow-cache-daemon
This is a daemon that polls a Rabbit queue for raw flow data, retrieves it, and stores it in shared memory for the stitching daemon.

#### netsage-flow-stitcher-daemon
This is a daemon that polls the shared memory cache for flow data, retrieves it, and stitches long-running flows based on 5-tuples and timestamps

#### netsage-tagger-daemon
This is a daemon that polls a Rabbit queue for flow data, retrieves it, and tags it with GeoIP/ASN/Organization information.

#### netsage-deidentifier-daemon

This is daemon that polls a Rabbit queue for tagged flow data, retrieves it, and deidentifies the IP addresses.

#### netsage-flow-mover-daemon
This is a daemon that polls a Rabbit queue for flow data, retrieves it, and pushes it to another queue 

