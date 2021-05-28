---
id: docker_install_simple
title:  Docker Installation Guide
sidebar_label: Docker Installation
---
In this deployment guide, you will learn how to deploy a basic Netsage setup that includes one sflow and/or one netflow collector.  If you have more than one collector of either type, or other special situations, see the Docker Advanced guide.

The Docker containers included in the installation are
 - rabbit    (the local RabbitMQ server)
 - sflow-collector   (receives sflow data and writes nfcapd files)
 - netflow-collector   (receives netflow data and writes nfcapd files)
 - importer   (reads nfcapd files and puts flows into a local rabbit queue)
 - logstash   (logstash pipeline that processes flows and sends them to their final destination, by default a local rabbit queue)
 - ofelia   (cron-like downloading of files used by the logstash pipeline)

The code and configs for the importer and logstash pipeline can be viewed in the netsage-project/netsage-pipeline github repo. See netsage-project/docker-nfdump-collector for code related to the collectors.


### 1. Set up Data Sources 
The data processing pipeline needs data to ingest in order to do anything, of course. There are three types of data that can be consumed.

 - sflow 
 - netflow
 - tstat

At least one of these must be set up on a sensor (flow exporter/router), to provide the incoming flow data. 
You can do this step later, but it will helpful to have it working first. 

Sflow and netflow data should be exported to the pipeline host where there are collectors (nfcapd and/or sfcapd processes) ready to receive it (see below). To use the default settings, send sflow to port 9998 and netflow to port 9999. On the pipeline host, allow incoming traffic from the flow exporters, of course.

Tstat data should be sent directly to the logstash input rabbit queue "netsage_deidentifier_raw" on the pipeline host. No collector is needed for tstat data. See the netsage-project/tstat-transport repo.  (From there, logstash will grab the data and process it the same way as it processes sflow/netflow data. (See the Docker Advanced guide.)

### 2. Clone the Netsage Pipeline Project

If you haven't already, install [Docker](https://www.docker.com) and [Docker Compose](https://docs.docker.com/compose/install/) and clone this project
```sh
git clone https://github.com/netsage-project/netsage-pipeline.git
```
(If you are upgrading to a new release, see the Upgrade section below!)

Then checkout the right version of the code.
```sh
git checkout {tag}
```
Replace "{tag}" with the release version you intend to use, e.g., "v1.2.8".  ("Master" is the development version and is not intended for general use!)
`git status` will confirm which branch you are on, e.g., master or v1.2.8.

### 3. Create Docker-compose.override.yml

Information in the `docker-compose.yml` file tells docker which containers (processes) to run and sets various parameters for them. 
Settings in the `docker-compose.override.yml` file will overrule and add to those. Note that docker-compose.yml should not be edited since upgrades will replace it. Put all customizations in the override file, since override files will not be overwritten.

Collector settings may need to be edited by the user, so the information that docker uses to run the collectors is specified (only) in the override file. Therefore, docker-compose_override.example.yml must always be copied to docker-compose_override.yml. 

```sh
cp docker-compose.override_example.yml docker-compose.override.yml
```

By default docker will bring up a single netflow collector and a single sflow collector. If this matches your case, you don't need to make any changes to the docker-compose.override_example.yml. If you have only one collector, remove or comment out the section for the one not needed so the collector doesn't run and simply create empty nfcapd files.
:::note
If you only have one collector, you should remove or comment out the section for the collector that is not used, so it doesn't run and just create empty files.
:::

This file also specifies port numbers, and directories for nfcapd files.  By default, the sflow collector will listen to udp traffic on localhost:9998, while the netflow collector will listen on port 9999,  and data will be written to `/data/input_data/`. Each collector is namespaced by its type so the sflow collector will write data to `/data/input_data/sflow/` and the netflow collector will write data to `/data/input_data/netflow/`.  Change these only if required.

Other lines in this file you can ignore for now. 

:::note
If you run into issues, try removing all the comments in the override file as they may conflict with the parsing done by docker-compose
:::


### 4. Create Environment File

{@import ../components/docker_env.md}

### 5. Choose Pipeline Version

Once you've created the docker-compose.override.xml file and finished adjusting it for any customizations, you're ready to select which version Docker should run.

```sh
./scripts/docker_select_version.sh
```
When prompted, select the **same version** you checked out earlier. 
This script will replace the version numbers of docker images in the docker-compose files with the correct values.

## Running the Collectors

After selecting the version to run, you could start the two flow collectors by themselves by running the following line. If you only need one of the collectors, remove the other from this command. 

(Or see the next section for how to start all the containers, including the collectors.)

```sh
docker-compose up -d sflow-collector netflow-collector
```

If the collector(s) are running properly, you should see nfcapd files in subdirectories of data/input_data/, and they should have sizes of more than a few hundred bytes. (See Troubleshooting if you have problems.)


## Running the Collectors and Pipeline

{@import ../components/docker_pipeline.md}

