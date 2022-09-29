---
id: docker_install_simple
title:  Docker Installation Guide
sidebar_label: Docker Installation
---
This deployment guide describes how to deploy a basic Netsage setup that includes one sflow and/or one netflow collector.  If you have more than one collector of either type, or other special situations, see the Docker Advanced guide.

The Docker containers included in the installation are
 - sfacctd_1 to _n - sflow collectors (one per sflow sensor) - each receives sflow data and writes it to a rabbit queue)
 - nfacctd_1 to _n - netflow collector (one per netflow sensor) - each receives netflow data and writes it to a rabbit queue)
 - rabbit    - the local RabbitMQ server
 - logstash  - logstash pipeline that pulls from the rabbit queue, processes flows, and sends to the final destination


### 1. Prepare a Pipeline Host
Decide where to run the Docker Pipeline, eg, create a VM. The default java heap size for logstash is 4GB so have at least 8GB of memory. Little disk space should be needed.

Install Docker Engine (docker-ce, docker-ce-cli, containerd.io) - see instructions at [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/).

This page has a good list of post-installation steps you may want or need to do: [https://docker-docs.netlify.app/install/linux/linux-postinstall/](https://docker-docs.netlify.app/install/linux/linux-postinstall/).

Start docker:
```
sudo systemctl docker start
```

Docker Compose is not part of Docker Engine, so must be installed separately from Docker's GitHub repository - see [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/).  You need to **specify version 1.29.2** (or newer) in the curl command. 

Check which file permissions new files are created with on the host. If the *logstash* user is not able to access the logstash config files in the git checkout, you'll get an error from logstash saying there are no .conf files found even though they are there. Defaults of 775 (u=rwx, g=rwx, o=rx) should work.

### 2. Set up Data Sources 
The data processing pipeline needs data to ingest in order to do anything, of course. There are three types of data that can be consumed.

 - sflow 
 - netflow
 - tstat

At least one of these must be set up on a **sensor** (i.e., flow **exporter** / router), to provide the incoming flow data. 
You can do this step later, but it will helpful to have it working first. 

Configure sflow and netflow to send flow data to the pipeline host. Each sensor/router should send to a different port. 
You will list the port numbers in the .env file (see below). 
Usually default settings are ok. (Please share your settings with us.)

On the pipeline host, configure the firewall to allow incoming traffic from the flow exporters, of course.

Tstat data should be sent directly to the logstash input rabbit queue "netsage_deidentifier_raw" on the pipeline host. No collector is needed for tstat data. See the netsage-project/tstat-transport repo.  (From there, logstash will grab the data and process it the same way as it processes sflow/netflow data.

Check to see if data is arriving with tcpdump.

### 3. Clone the Netsage Pipeline Project

Clone the netsage-pipeline project from github.
```sh
git clone https://github.com/netsage-project/netsage-pipeline.git
```

When the pipeline runs, it uses some of the files that are in the git checkout, so it is important to checkout the correct version.   
Move into the netsage-pipeline/ directory (**all git, docker, and other commands below must be run from inside this directory!**), then checkout the most recent version of the pipeline (normally the most recent tag). It will say you are in 'detached HEAD' state.
```sh
cd netsage-pipeline
git checkout {tag}
```
Replace "{tag}" with the release version you intend to use, e.g., "v2.0.0".  ("Master" is the development version and is not intended for general use!)
`git status` will confirm which branch you are on, e.g., master or v2.0.0.

>Files located in the git checkout that are used by the docker containers and cron:
>- the .env file (created by setup script from example file)
>- docker-compose.yml (created by setup script from example file) and docker-compose.override.yml (optional)
>- logstash config files in conf-logstash/
>- non-ORIG nfacctd and sfacctd config files in conf-pmacct/ (created by setup script)
>- cron jobs use non-ORIG files in bin/ (created by setup script) and save files to logstash-downloads/ 
>- logstash may write to or read from logstash-temp/ when it stops or starts
>On upgrade, example and ORIG files and files in conf-logstash/ will be overwritten.

### 4. Create the Environment File

Next, copy `env.example` to `.env`  then edit the .env file to set the number of sensors of each type, the sensor names and ports, and where to send processed flows.

```sh
cp env.example  .env
```

The .env file is used in multiple ways - by setup scripts as well as by docker-compose and hence logstash and rabbitmq. Everything you need to set is in this one location.

By default, the number of sflowSensors and netflowSensors is set to 1 at the top.  If you know from the start that you will have only 1 sensor, set either sflowSensors or netflowSensors to 0 and comment out the sensor name and port below. If you know that you will have more than 1 sensor of the same type, specify the number and add variables for the extra sensor names and ports. Note that the variable names need to have _1 replaced by _2, etc. For example,

```
sflowSensors=1
netflowSensors=2

# sflow sensors:
sflowSensorName_1=MyNetwork New York Sflow
sflowPort_1=8010

# netflow sensors:
netflowSensorName_1=MyNetwork LA Netflow
netflowPort_1=9000

netflowSensorName_2=MyNetwork Seattle Netflow
netflowPort_2=9010
```

:::note
Sensor names uniquely identify the source of the data and will be shown in the Grafana dashboards so they should be understandable by a general audience.  For example, your sensor names might be "MyNet New York Sflow" or "MyNet New York to London". (Running your proposed names by a Netsage admin would be helpful.)

Also, pmacct does not properly handle sensor names containing commas!
:::

You will also want to edit the **rabbit_output** variables. This section defines where the final data will land after going through the pipeline.  By default, it will be written to a rabbitmq queue on `rabbit`, ie, the local rabbitMQ server running in the docker container, but there is nothing provided to do anything further with it.

To send processed flow data to us, you will need to obtain settings for this section from your contact. A new queue may need to be set up on our end, as well as allowing traffic from your pipeline host. (On our end, data from the this final rabbit queue will be moved into an Elasticsearch instance for storage and viewing in Netsage Portals.)


### 5.  Run the Pmacct/Compose Setup Script

```sh
./setup-pmacct-compose.sh
```

This script will use settings in the .env file to create pmacct (ie, nfacctd and sfacctd) config files in **conf-pmacct/** from the .ORIG files in the same directory. 

It will also create **docker-compose.yml** from docker-compose.example.yml, filling in the correct number of nfacctd and sfacctd services and substituting ${var} values from the .env file. (This is needed since pmacct can't use environment variables directly, like logstash can.)

Information in the docker-compose.yml file tells docker which containers to run (or stop).
if needed, you can create a docker-compose.override.yml file; settings in this file will overrule and add to those in docker-compose.yml. All customizations should go in the override file, which will not be overwritten.

Check the docker-compose file to be sure it looks ok and is consistent with the new config files in conf-pmacct/. All environment variables (${x}) should be filled in. Under ports, there should be two numbers separated by a colon, eg,  "18001:8000/udp"

### 6. Run the Cron Setup Script

```sh
./setup-cron.sh
```

This script will create docker-netsage-downloads.cron and restart-logstash-container.cron in the checkout's **cron.d/** directory, along with matching .sh files in **bin/**. These are based on .ORIG files in the same directories but have required information filled in.

The docker-netsage-downloads cron job runs the downloads shell script, which will get various files required by the pipeline from scienceregistry.grnoc.iu.edu on a weekly basis.  
The restart cron job runs the restart shell script, which restarts the logstash container once a day. Logstash must be restarted to pick up any changes in the downloaded files.

**Note that you need to manually check and then copy the .cron files to /etc/cron.d/.** 

```sh
sudo cp cron.d/docker-netsage-downloads.cron  /etc/cron.d/
sudo cp cron.d/restart-logstash-container.cron  /etc/cron.d/
```

Also, manually run the downloads script to immediately download the required external files.

```sh
bin/docker-netsage-downloads.sh
```

Check to be sure files are in logstash-downloads/.

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
etc.
```

`--timestamps`, `--tail`,  and `--since` are also useful -- look up details in Docker documentation.

When running properly, logstash logs should end with a line saying how many pipelines are running and another about connecting to rabbitmq. 

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

In your browser, go to ``` https://<pipeline host>/rabbit ```  Login with username *guest*, password *guest*.  Look at the small graph showing rates for incoming messages, acks, etc. You should see bursts of incoming messages (usually once a minute for netflow and once every 5 min for sflow) and no long-term buildup of messages in the other graph.

### 10. Check for processed flows

- Ask your contact to check for flows and/or look at dashboards in your grafana portal if it's already been set up. Flows should appear after 10-15 minutes.
- Check to be sure the sensor name(s) are correct in the portal. 
- Check flow sizes and rates to be sure they are reasonable. (If sampling rate corrections are not being done properly, you may have too few flows and flows which are too small.) You contact can check to see whether flows have @sampling_corrected=yes (a handful from the startup of netflow collection may not) and to check for unusal tags on the flows.

If you are not seeing flows, see the Troubleshooting section of the documentation.




