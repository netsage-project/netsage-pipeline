---
id: tstat
title: Tstat
sidebar_label: Tstat
---

## Netsage Usage

[Tstat](http://tstat.polito.it/) is a passive sniffer that provides insights into traffic patterns.  The Netsage project [tstat-transport](https://github.com/netsage-project/tstat-transport) provides a way to send the captured data to a rabbitmq host where it can then be processed by a [logstash pipeline](logstash), stored in elasticsearch, and finally displayed in our Grafana [dashboards](https://github.com/netsage-project/netsage-grafana-configs).

## Docker 

Docker images exist for the tstat process, as well as the sending of tstat logs to the appropriate RabbitMQ server.  This flow is still in a beta state and is in development.  The initial documentation is available [here](https://github.com/netsage-project/tstat-transport/blob/master/docs/docker.md).  



