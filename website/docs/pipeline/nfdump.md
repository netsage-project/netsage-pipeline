---
id: nfdump
title: Nfdump
sidebar_label: Nfdump
---

nfdump is a toolset in order to collect and process netflow and sflow data, sent from netflow/sflow compatible devices. The toolset supports netflow v1, v5/v7,v9,IPFIX and SFLOW. nfdump supports IPv4 as well as IPv6.

## Netsage Usage

The nfdump utility is used to collect netflow and sflow data and persisted to disk.  At which stage the data is processed by the [importer](importer) and sent to rabbitmq.  The [logstash](logstash) pipeline then processes the messages same as tstat with the same transformations.  The final result will eventually make it to the [grafana dashboard](https://github.com/netsage-project/netsage-grafana-configs).

## Docker

The nfdump process can be invoked locally or using a docker container.  The docker deployment guide walks you through utilizing the docker container created.  The docker image definitions can be found [here](https://github.com/netsage-project/docker-nfdump-collector)