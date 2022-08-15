---
id: docker_install_simple
title:  Docker Installation Guide
sidebar_label: Docker Installation
---
In this deployment guide, you will learn how to deploy a basic Netsage setup that includes one sflow and/or one netflow collector.  If you have more than one collector of either type, or other special situations, see the Docker Advanced guide.

The Docker containers included in the installation are
 - sfacctd_1 (sflow collector - receives sflow data and writes it to a rabbit queue)
 - nfacctd_1 (netflow collector - receives netflow data and writes it to a rabbit queue)
 - rabbit    (the local RabbitMQ server)
 - logstash  (logstash pipeline that pulls from the rabbit queue, processes flows, and sends to the final destination)


### 1. Set up a Pipeline Host
Decide where to run the Docker Pipeline and get it set up. The default java heap size for logstash is 4GB so have at least 8GB of memory. Little disk space should be needed.

Install Docker Engine (docker-ce, docker-ce-cli, containerd.io) - see instructions at [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/).

Start docker
```
sudo systemctl docker start
```

Install Docker Compose from Docker's GitHub repository - see [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/).  You need to **specify version 1.29.2** (or newer) in the curl command. 

Check which file permissions new files are created with. If the *logstash* user is not able to access the logstash config files in the git checkout, you'll get an error from logstash saying there are no .conf files found even though they are there. Defaults of 775 (u=rwx, g=rwx, o=rx) should work.

### 2. Set up Data Sources 
The data processing pipeline needs data to ingest in order to do anything, of course. There are three types of data that can be consumed.

 - sflow 
 - netflow
 - tstat

At least one of these must be set up on a **sensor** (i.e., flow **exporter** / router), to provide the incoming flow data. 
You can do this step later, but it will helpful to have it working first. Check it with tcpdump on the pipeline host.

Configure sflow and netflow to send flow data to the pipeline host. Each sensor/router should send to a different port. 
You will list the port numbers in the .env file (see below). 
Usually default settings are ok. (Please share your settings with us.)

On the pipeline host, configure the firewall to allow incoming traffic from the flow exporters, of course.

Tstat data should be sent directly to the logstash input rabbit queue "netsage_deidentifier_raw" on the pipeline host. No collector is needed for tstat data. See the netsage-project/tstat-transport repo.  (From there, logstash will grab the data and process it the same way as it processes sflow/netflow data.


### 3. Clone the Netsage Pipeline Project

Clone the netsage-pipeline project from github.
```sh
git clone https://github.com/netsage-project/netsage-pipeline.git
```

When the pipeline runs, it uses some of the files that are in the git checkout, so it is important to checkout the correct version.   
Move into the netsage-pipeline/ directory (**all git, docker, and other commands below must be run from inside this directory!**), then checkout the most recent version of the pipeline (the most recent tag). It will say you are in 'detached HEAD' state.
```sh
cd netsage-pipeline
git checkout {tag}
```
Replace "{tag}" with the release version you intend to use, e.g., "v2.0.0".  ("Master" is the development version and is not intended for general use!)
`git status` will confirm which branch you are on, e.g., master or v2.0.0.

### 4. Create the Environment File

Next, copy `env.example` to `.env`  then edit the .env file to set the sensor names, ports, and where to send processed flows.

```sh
cp env.example  .env
```

1. By default, the number of sflowSensors and netflowSensors is set to 1 at the top.  If you know from the start that you will have only 1 sensor, set either sflowSensors or netflowSensors to 0 and comment out the sensor name and port below.

    If you will have more than 1 of one type of sensor, see the Docker Advanced Options documentation.

2. In the next section of the .env file, declare the name of sflow sensor 1 and the port to which the exporter is sending the flows. Similarly for netflow sensor 1.

3. You will also want to edit the **rabbit_output** variables. This section defines where the final data will land after going through the pipeline.  By default, it will be written to a rabbitmq queue on `rabbit`, ie, the local rabbitMQ server running in the docker container, but there is nothing provided to do anything further with it.

    To send processed flow data to Indiana University, you will need to obtain settings for this section from your contact. A new queue may need to be set up at IU, as well as allowing traffic from your pipeline host. (At IU, data from the this final rabbit queue will be moved into an Elasticsearch instance for storage and viewing in Netsage Portals.)


:::note
Sensor names uniquely identify the source of the data and will be shown in the Grafana dashboards so they should be understandable by a general audience.  For example, your sensor names might be "MyNet New York Sflow" or "MyNet New York to London". (Running your proposed names by a Netsage admin would be helpful.)
:::

### 5.  Run the pmacct setup script

```sh
./setup-pmacct.sh
```

This script will use settings in the .env file to create pmacct (ie, nfacctd and sfacctd) config files in conf-pmacct/ from the .ORIG files in the same directory. 

It will also create **docker-compose.override.yml** from docker-compose.override_example.yml, or update it if it exists, filling in ${var} values from the .env file. (This is needed since pmacct can't use environment variables directly, like logstash can.)

Information in the docker-compose.yml file tells docker which containers (processes) to run and sets various parameters for them. 
Settings in the docker-compose.override.yml file will overrule and add to those. Note that docker-compose.yml should not be edited since upgrades will replace it. All customizations go in the override file, which will not be overwritten.

Check the override file to be sure it looks ok and is consistent with the new config files in conf-pmacct/. All environment variables (${x}) should be filled in.

### 6. Run the cron setup script

```sh
./setup-cron.sh
```

This script will create docker-netsage-downloads.cron and .sh and restart-logstash-container.cron and .sh files in cron.d/ and bin/ from .ORIG files in the same directories, filling in required information.

The downloads cron job runs the downloads shell script, which will get various files required by the pipeline from scienceregistry.grnoc.iu.edu on a weekly basis.  
The restart cron job runs the restart shell script, which restarts the logstash container once a day. Logstash must be restarted to pick up any changes in the downloaded files.

Note that you need to manually check and then copy the .cron files to /etc/cron.d/.

```sh
sudo cp cron.d/docker-netsage-downloads.cron  /etc/cron.d/
sudo cp cron.d/restart-logstash-container.cron  /etc/cron.d/
```

Also, manually run the downloads script to immediately download the required external files.

```sh
bin/docker-netsage-downloads.sh
```

Check to be sure files are in downloads/.

>Files located in the git checkout that are used by the docker services and cron:
>- the .env file
>- docker-compose.yml and docker-compose.override.yml
>- files in conf-logstash/
>- non-ORIG files in conf-pmacct/
>- cron jobs use non-ORIG files in bin/ and cron.d/ and write to logstash-downloads/
>- logstash may write to or read from logstash-temp/
> On upgrade, docker-compose.yml, files in conf-logstash, ORIG and example files will be overwritten.

### 8. Start up the Docker Containers

Start up the pipeline (all containers) using

```sh
docker-compose up -d
```

This command will pull down all required docker images and start all the services/containers as listed in the docker-compose.yml and docker-compose.override.yml files.
"-d" runs the containers in the background.

You can see the status of the containers and whether any have died (exited) using these commands
```sh
docker-compose ps
docker container ls
```

To check the logs for each of the containers, run

```sh
docker-compose logs logstash
docker-compose logs rabbit
docker-compose logs sfacctd_1
docker-compose logs nfacctd_1
```

Add `-f`, e.g. `-f logstash` to see new log messages as they arrive.  `--timestamps`, `--tail`,  and `--since` are also useful -- look up details in Docker documentation.

To shut down the pipeline (all containers) use

```sh
# docker-compose down
```

**Run all commands from the netsage-pipeline/ directory.** 

>Note that if the pipeline host is rebooted, the containers will not restart automatically.
>
>If this will be a regular occurance on your host, you can add `restart:always` to each service in the docker-compose.override file (you may need to add any missing services to that file).

### 9. Check the RabbitMQ User Interface

The rabbitMQ user interface can be used to see if there are incoming flows from pmacct processes and if those flows are being comsumed by logstash.

In your browser, go to ``` https://<pipeline host>/rabbit ```  Login with username guest, password guest.  Look at the small graph showing rates for incoming messages, acks, etc.

### 10. Check for processed flows

- Ask your contact at IU to check for flows and/or look at dashboards in your grafana portal. Flows should appear after 10-15 minutes.
- Check to be sure the sensor name(s) are correct in the portal. 
- Check flow sizes and rates to be sure they are reasonable. (If sampling rate corrections are not being done properly, you may have too few flows and flows which are too small.) You IU contact can check to see whether flows have @sampling_corrected=yes (a handful from the startup of netflow collection may not) and to check for unusal tags on the flows.

If you are not seeing flows, see the Troubleshooting section of the documentation.




