---
id: docker_install_simple
title: Docker Default Installation Guide
sidebar_label: Docker Simple
---
In this deployment guide, you will learn how to deploy docker-based sflow and netflow collectors (see https://github.com/netsage-project/docker-nfdump-collector) and a basic docker flow processing pipeline. The collectors will save incoming flow data to disk, while the pipeline Importer will read it and pipeline Lostash filters will process it. Without any modification, 1 sflow collector, 1 netflow collector, and a flow processing pipeline will run. If you have only 1 collector, this guide will show you how to disable the unnecessary one.  If you need 2 or more collectors of the same type, please read "Docker Advanced" after reading through this guide.

### First

If you haven't already, install Docker/compose and clone this project from github (https://github.com/netsage-project/netsage-pipeline.git).

### Docker-compose.override.yml

The pattern for running the Pipeline, with docker-based collectors, is defined in the docker-compose.override_example.yml. Copy this to docker-compose.override.yml. 

```sh
cp docker-compose.override_example.yml docker-compose.override.yml
```

By default this will bring up a single netflow collector and a single sflow collector. For most people this is more than enough. If you're sticking to the default you don't need to make any changes to the docker-compose.override_example.yml

:::note
You may need to remove all the comments in the override file as they may conflict with the parsing done by docker-compose
:::

:::note
If you are only interested in netflow OR sflow data, you should remove the section for the collector that is not used.
:::

This file also specifies port numbers and directories for nfcapd files.  By default, the sflow collector will listen to udp traffic on localhost:9998, while the netflow collector will listen on port 9999,  and data will be written to `/data/input_data/` . Each collector is namespaced by its type so the sflow collector will write data to `/data/input_data/sflow/` and the netflow collector will write data to `/data/input_data/netflow/`.  

### Environment File

{@import ../components/docker_env.md}

### Pipeline Version

Once you've created the docker-compose.override.xml and finished adjusting it for any customizations, you're ready to select your version.

```sh
git fetch
git checkout "tag name"
./scripts/docker_select_version.sh
```
Replace "tag name" with the version you intend to use, e.g., "v1.2.5". Select the same version when prompted by docker_select_version.sh.

### Running the Collectors

After selecting the version to run, you can start the two flow collectors by running the following line. If you only need one of the collectors, remove the other from this command.

```sh
docker-compose up -d sflow-collector netflow-collector
```

### Running the Pipeline

{@import ../components/docker_pipeline.md}

## Data sources 
The data processing pipeline needs data to ingest in order to do anything, of course. There are three types of data that can be consumed.

 - sflow 
 - netflow
 - tstat

At least one of these must be set up on a sensor to provide the incoming flow data. 

Sflow and netflow data should be exported to the pipeline host where nfcapd and/or sfcapd collectors are ready to receive it.

Tstat data should be sent directly to the logstash input RabbitMQ queue (the same one that the Importer writes to, if it is used). From there, the data will be processed the same as sflow/netflow data. (See the Docker Advanced guide.)

## Upgrading

{@import ../components/docker_upgrade.md}
