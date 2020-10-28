---
id: nfdump
title: Nfdump
sidebar_label: Nfdump
---

Nfdump is a toolset used to collect and process netflow and sflow data that is sent from netflow/sflow compatible devices. The toolset supports netflow v1, v5/v7, v9, IPFIX and SFLOW. Nfdump supports IPv4 as well as IPv6.

## Netsage Usage

The nfdump utility (nfcapd and/or sfcapd processes) is used to collect netflow and sflow data and save it to disk (as nfcapd files).  The files are then processed by the [importer](importer) and sent to RabbitMQ. From there, the [logstash](logstash) pipeline ingests the flows and processes them in exactly the same way as it processes tstat flows.  The data is eventually saved in elasticsearch and visualized by [grafana dashboards](https://github.com/netsage-project/netsage-grafana-configs).

One may also use the nfdump command interactively to view the flows in a nfcapd file in a terminal window.

## Docker

The nfdump processes can be invoked locally or using a Docker container.  The Docker Deployment Guide walks you through utilizing the Docker container.  The Docker image definitions can be found [here](https://github.com/netsage-project/docker-nfdump-collector)
