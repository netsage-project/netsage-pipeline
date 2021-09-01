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

At least one of these must be set up on a *sensor* (i.e., flow *exporter* / router), to provide the incoming flow data. 
You can do this step later, but it will helpful to have it working first. 

Sflow and netflow data should be exported to the pipeline host where there will be *collectors* (nfcapd and/or sfcapd processes) ready to receive it (see below). To use the default settings, send sflow to port 9998 and netflow/IPFIX to port 9999. On the pipeline host, allow incoming traffic from the flow exporters, of course.

Tstat data should be sent directly to the logstash input rabbit queue "netsage_deidentifier_raw" on the pipeline host. No collector is needed for tstat data. See the netsage-project/tstat-transport repo.  (From there, logstash will grab the data and process it the same way as it processes sflow/netflow data. (See the Docker Advanced guide.)

### 2. Set up a Pipeline Host
Decide where to run the Docker Pipeline and get it set up. Adjust iptables to allow the flow exporters (routers) to send flow data to the host. 

Install Docker Engine (docker-ce, docker-ce-cli, containerd.io) - see instructions at [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/).

Install Docker Compose from Docker's GitHub repository - see [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/).  You need to **specify version 1.29.2** (or newer) in the curl command. 

Check default file permissions. If the *logstash* user is not able to access the logstash config files in the git checkout, you'll get an error from logstash saying there are no .conf files found even though they are there. Various components also need to be able to read and write to the data/ directory in the checkout. Defaults of 775 (u=rwx, g=rwx, o=rx) should work.

### 3. Clone the Netsage Pipeline Project

Clone the netsage-pipeline project from github.
```sh
git clone https://github.com/netsage-project/netsage-pipeline.git
```

When the pipeline runs, it uses the logstash conf files that are in the git checkout (in conf-logstash/), as well as a couple other files like docker-compose.yml, so it is important to checkout the correct version.

Move into the netsage-pipeline/ directory (**all git and docker commands must be run from inside this directory!**), then checkout the most recent version of the code. It will say you are in 'detached HEAD' state.
```sh
git checkout {tag}
```
Replace "{tag}" with the release version you intend to use, e.g., "v1.2.11".  ("Master" is the development version and is not intended for general use!)
`git status` will confirm which branch you are on, e.g., master or v1.2.11.

### 4. Create Docker-compose.override.yml

Information in the `docker-compose.yml` file tells docker which containers (processes) to run and sets various parameters for them. 
Settings in the `docker-compose.override.yml` file will overrule and add to those. Note that docker-compose.yml should not be edited since upgrades will replace it. Put all customizations in the override file, since override files will not be overwritten.

Collector settings may need to be edited by the user, so the information that docker uses to run the collectors is specified (only) in the override file. Therefore, docker-compose_override.example.yml must always be copied to docker-compose_override.yml. 

```sh
cp docker-compose.override_example.yml docker-compose.override.yml
```

By default docker will bring up a single sflow collector and a single netflow collector that listen to udp traffic on ports localhost:9998 and 9999. If this matches your case, you don't need to make any changes to the docker-compose.override_example.yml. 

- If you have only one collector, remove or comment out the section for the one not needed so the collector doesn't run and simply create empty nfcapd files.
- If the collectors need to listen to different ports, make the appropriate changes here in both the "command:" and "ports:" lines. 
- By default, the collectors will save flows to nfcapd files in sflow/ and netflow/ subdirectories in `./data/input_data/` (i.e., the data/ directory in the git checkout).  If you need to save the data files to a different location, see the Docker Advanced section.

Other lines in this file you can ignore for now. 

:::note
If you run into issues, try removing all the comments in the override file as they may conflict with the parsing done by docker-compose, though we have not found this to be a problem.
:::

### 5. Choose Pipeline Version

Once you've created the docker-compose.override.xml file and finished adjusting it for any customizations, you're ready to select which image versions Docker should run.

```sh
./scripts/docker_select_version.sh
```
When prompted, select the **same version** you checked out earlier. 

This script will replace the version numbers of docker images in docker-compose.override.yml and docker-compose.yml with the correct values.

### 6. Create Environment File

{@import ../components/docker_env.md}

## Testing the Collectors

At this point, you can start the two flow collectors by themselves by running the following line. If you only need one of the collectors, remove the other from this command.  

(See the next section for how to start all the containers, including the collectors.)

```sh
docker-compose up -d sflow-collector netflow-collector
```

Subdirectories for sflow/netflow, year, month, and day are created automatically under `data/input_data/`. File names contain dates and times.
These are not text files; to view the contents, use an [nfdump command](http://www.linuxcertif.com/man/1/nfdump/) (you will need to install nfdump). 
Files will be deleted automatically by the importer as they age out (the default is to keep 3 days).  

If the collector(s) are running properly, you should see nfcapd files being written every 5 minutes and they should have sizes of more than a few hundred bytes. (Empty files still have header and footer lines.)  
See Troubleshooting if you have problems.

To stop the collectors
```sh
docker-compose down 
```

## Running the Collectors and Pipeline

{@import ../components/docker_pipeline.md}

