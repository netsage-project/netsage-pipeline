---
id: tstat
title: Tstat
sidebar_label: Tstat
---

[Tstat](http://tstat.polito.it/) is a passive sniffer that provides insights into traffic patterns.  The Netsage project [tstat-transport](https://github.com/netsage-project/tstat-transport) provides a way to send data the captured data to a rabbitmq host which is processed by [logstash](logstash) than displayed in our [dashboard](https://github.com/netsage-project/netsage-grafana-configs).

## Docker 

There are docker images created for the tstat process as well as the sendining of tstat logs to the appropriate rabbit MQ server.  That flow is still in a beta state and is in progress.  The initial documentation is available [here](https://github.com/netsage-project/tstat-transport/blob/master/docs/docker.md).  



