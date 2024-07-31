---
id: nfdump
title: Sflow/Netflow Data Collection
sidebar_label: Sflow/Netflow Data
---

Sflow and Netflow export can be configured on appropriate network devices. Netsage uses tools in the Nfdump package to collect and process the resulting flow data.  The toolset supports netflow v1, v5/v7, v9, IPFIX and SFLOW, IPv4 as well as IPv6.

## Netsage Usage

Nfcapd and/or sfcapd processes (from the nfdump package) are used to collect incoming netflow and/or sflow data and save it to disk in nfcapd files.  The files are then read by the [importer](importer), which uses an nfdump command, and sent to RabbitMQ. From there, the [logstash](logstash) pipeline ingests the flows and processes them in exactly the same way as it processes tstat flows.  The data is eventually saved in elasticsearch and visualized by [grafana dashboards](https://github.com/netsage-project/netsage-grafana-configs).

One may also use the nfdump command interactively to view the flows in a nfcapd file in a terminal window.

## Docker Deployment

The nfdump/nfcapd/sfcapd processes can be invoked locally or using a Docker container.  The Docker deployment of the Pipeline uses an nfdump Docker container. (See the Docker Deployment Guide.) The Docker image definitions can be found [HERE](https://github.com/netsage-project/docker-nfdump-collector)
