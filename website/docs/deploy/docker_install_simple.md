---
id: docker_install_simple
title: Docker Default Installation Guide
sidebar_label: Docker Simple
---
The default Docker installation can bring up 2 nfdump collectors and the Netsage Pipeline (Importer plus logstash pipeline). It can work with one sflow and/or one netflow and/or any number of tstat data sources.

### To begin 

Install Docker/compose and clone this project (netsage-pipeline) from github.

There are four things that need to be done to make the nfdump sflow and netflow collectors (sfcapd and nfcapd processes that listen for incoming flow data) work with the Netsage Pipeline.

- an ENV value needs to be set that sets the sensor name.
- a unique data output path should be set.
- importer needs to be updated to be aware of the filepath and the sensor name.

### Docker-compose.override.yml

The default pattern for running the Pipeline is defined in the docker-compose.override_example.yml. Copy this to docker-compose.override.yml. By default we bring up a single netflow collector and a single sflow collector. For most people this is more than enough. You may wish to delete collectors you're not using.

```sh
cp docker-compose.override_example.yml docker-compose.override.yml
```

If you're sticking to the default you don't need to make any changes to the docker-compose.override_example.yml

:::note
You may need to remove all the comments in the override file as they may conflict with the parsing done by docker-compose
:::

:::note
If you are only interested in netflow OR sflow data, you should remove the section for the collector that is not used.
:::

### Pipeline Version

Once you've created the docker-compose.override.xml and finished adjusting it for any customizations, then you're ready to select your version.

- Select Release version
  - `git fetch; git checkout <tag name>` replace "tag name" with v1.2.5 or the version you intend to use.
  - Then also please select the version you wish to use by running `./scripts/docker_select_version.sh`

### Environment File

{@import ../components/docker_env.md}

### Running the Collectors

After selecting the version to run, you can start the two collectors by running the following line

```sh
docker-compose up -d sflow-collector netflow-collector
```

By default the container comes up and will write data (as nfcapd files) to `/data/input_data/` . Each collector is namespaced by its type so sflow collector will write data to `/data/input_data/sflow/` and the netflow collector will write data to `/data/input_data/netflow/`.

By default, the sflow collector will listen to udp traffic on localhost:9998, while the netflow collector will listen on port 9999.

These are set in the docker-compose.override.yml file.

### Running the Pipeline

{@import ../components/docker_pipeline.md}

## Data sources
The data processing pipeline needs data to ingest in order to do anything, of course. There are two types of data that can be consumed.

sflow or netflow
tstat
At least one of these must be set up on a sensor to provide the incoming flow data.

Sflow and netflow data should be sent to ports on the pipeline host where nfcapd and/or sfcapd are ready to receive it.

Tstat data should be sent directly to the logstash input RabbitMQ queue (the same one that the Importer writes to, if it is used). From there, the data will be processed the same as sflow/netflow data.

## Upgrading

{@import ../components/docker_upgrade.md}
