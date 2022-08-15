---
id: tstat
title: Tstat Data Export
sidebar_label: Tstat Data
---

**[Tstat](http://tstat.polito.it/)** is a passive sniffer that provides insights into traffic patterns.  

The **Netsage [tstat-transport](https://github.com/netsage-project/tstat-transport) project** provides client programs to parse the captured data and send it to a rabbitmq host where it can then be processed by the [logstash pipeline](logstash), stored in elasticsearch, and finally displayed in our Grafana [dashboards](https://github.com/netsage-project/netsage-grafana-configs).

Tstat is only appropriate for certain situations, eg, tracking traffic into and out of data archives. It does not do sampling and exports only complete flows. It also provides additional information beyond what sflow and netflow provide.

In the Netage Pipeline, tstat data is treated the same as sflow and netflow data, but the logstash aggregation step is skipped since it is not needed.

Docker images exist on Docker Hub for tstat and tstat_transport. This is still in a beta state and is in development.  The initial documentation is available [here](https://github.com/netsage-project/tstat-transport/blob/master/docs/docker.md).  



