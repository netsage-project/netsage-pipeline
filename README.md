# netsage-pipeline

To start the pipeline containers, run:
```
docker-compose up -d
```

The [Netsage](https://netsage.io) Flow Processing Pipeline includes several components for processing network flow data, including importing, deidentification, metadata tagging, flow stitching, etc.

Information on the NetSage Science Registry is [here](https://netsage.io/scienceregistry/)

# Docker Installation Guide

The Docker containers included in the installation are:
* **rabbit**: the local RabbitMQ server
* **sflow-collector**: receives sflow data and writes nfcapd files
* **netflow-collector**: receives netflow data and writes nfcapd files
* **importer**: reads nfcapd files and puts flows into a local rabbit queue
* **logstash**: logstash pipeline that processes flows and sends them to their final destination, by default a local rabbit queue
* **manager**: cron-like downloading of files used by the logstash pipeline

The code and configs for the importer and logstash pipeline can be viewed in the [netsage-project/netsage-pipeline](https://github.com/netsage-project/netsage-pipeline) github repo. See [netsage-project/docker-nfdump-collector](https://github.com/netsage-project/docker-nfdump-collector) for code related to the collectors.

An advanced Docker configuration guide is available for installations with more than one netflow/sflow sensor: [Advanced Configuration Guide](https://github.com/netsage-project/netsage-pipeline/blob/master/docker-advanced.md)

---

## 1. Set up Data Sources

There are two types of data that can be consumed:
* sflow
* netflow/IPFIX

At least one of these must be set up on a sensor (i.e., flow exporter / router), to provide the incoming flow data. You can do this step later, but it will helpful to have it working first.

Sflow and netflow data should be exported to the pipeline host where there will be collectors (nfcapd and/or sfcapd processes) ready to receive it (see below). To use the default settings, send sflow to port 9998 and netflow/IPFIX to port 9999. On the pipeline host, allow incoming traffic from the flow exporters.

---

## 2. Set up a Pipeline Host

Decide where to run the Docker Pipeline and get it set up. Adjust iptables to allow the flow exporters (routers) to send flow data to the host.

1.  **Install Docker Engine** - see instructions at [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/).
2.  **Install Docker Compose** from Docker's GitHub repository - see [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/).
3.  **Check default file permissions**. If the logstash user is not able to access the logstash config files in the git checkout, you'll get an error from logstash saying there are no .conf files found even though they are there. Various components also need to be able to read and write to the `data/` directory in the checkout. Defaults of 775 (u=rwx, g=rwx, o=rx) should work.

---

## 3. Clone the Netsage Pipeline Project

Clone the netsage-pipeline project from github:

```bash
git clone https://github.com/netsage-project/netsage-pipeline.git
```

---

## 4. Create Docker-compose.override.yml

Information in the `docker-compose.yml` file tells docker which containers (processes) to run and sets various parameters for them. Settings in the `docker-compose.override.yml` file will overrule and add to those. Note that `docker-compose.yml` should not be edited since upgrades will replace it. Put all customizations in the override file, since override files will not be overwritten.

Collector settings may need to be edited by the user, so the information that docker uses to run the collectors is specified (only) in the override file. Therefore, `docker-compose.override_example.yml` must always be copied to `docker-compose.override.yml`.

```bash
cp docker-compose.override_example.yml docker-compose.override.yml
```

By default docker will bring up a single sflow collector and a single netflow collector that listen to udp traffic on ports **localhost:9998** and **localhost:9999**. If this matches your case, you don't need to make any changes to the example file.

If you have only one collector, remove or comment out the section for the one not needed so the collector doesn't run and simply create empty nfcapd files. If the collectors need to listen to different ports, make the appropriate changes here in both the "command:" and "ports:" lines. By default, the collectors will save flows to nfcapd files in `sflow/` and `netflow/` subdirectories in `./data/input_data/`.

> **Note:** If you run into issues, try removing all the comments in the override file as they may conflict with the parsing done by docker-compose.

---

## 5. Create Environment File

Next, copy `env.example` to `.env`:

```bash
cp env.example .env
```

then edit the `.env` file to set the sensor names to unique identifiers:

```ini
# Importer settings
sflowSensorName=My sflow sensor name
netflowSensorName=My netflow sensor name
```

> **Note:** These names uniquely identify the source of the data and will be shown in the Grafana dashboards. In elasticsearch, they are saved in the `meta.sensor_id` field. Choose names that are human readable, meaningful, and unique.

You will also want to edit the Logstash output rabbit queue section. This defines where the final data will land. By default, it will be written to a rabbitmq queue on `rabbit` (the local rabbitMQ server). If sending this data to an external endpoint (such as TACC), credentials will need to be obtained from the endpoint administration:

```ini
rabbitmq_output_host=rabbit@mynet.edu
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
rabbitmq_output_key=netsage_archive_input
```

---

## Running the Collectors and Pipeline

Start up the pipeline (all containers) using:

```bash
docker-compose up -d
```

### Useful Commands:

* **Check status**: `docker-compose ps`
* **Check logs**: `docker-compose logs -f [container_name]` (e.g., `logstash`, `importer`, or `rabbit`)
* **Shut down**: `docker-compose down`

Run all commands from the `netsage-pipeline/` directory.

---
*Copyright © 2025 NetSage*
