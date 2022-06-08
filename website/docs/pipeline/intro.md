---
id: intro
title: Intro
sidebar_label: Intro
---
## Network Flows

A flow is defined as a series of packets with the same source IP and port, destination IP and port, and protocal (the "5-tuple"). 

## The NetSage Pipeline

The Netsage Flow Processing Pipeline is composed of several components for processing network flow data, including collection, deidentification, metadata tagging, flow stitching, etc.
There are many ways the components can be combined, configured, and run. These documents will describe the standard "simple" set up and provide information for more complex configurations.

### Flow Export

In Netsage, "sensor(s)" are "flow exporters," i.e.,  network devices such as routers that are configured to collect flow data ([tstat](http://tstat.polito.it/), [sflow](https://www.rfc-editor.org/info/rfc3176), or [netflow/IPFIX](https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html)) and send it to a "Netsage pipeline" on a "pipeline host" for processing. 

### Pipeline Components

The Netsage Flow Processing Pipeline is made of the following components

 - [Pmacct](https://github.com/pmacct/pmacct): the pmacct package includes sfacctd and nfacctd daemons which receive sflow and netflow/IPFIX flows, respectively. They can also do some processing and filtering, but we use these options very minimally. They send the flows to a rabbitmq queue.
 - [RabbitMQ](https://www.rabbitmq.com/): Used for message queueing and passing at a couple of points in the full pipeline.
 - [Logstash](https://www.elastic.co/logstash): A logstash pipeline performs a variety of operations on the flow data to transform it and add additional information.  ([Doc](logstash.md))
 - [Elasticsearch](https://www.elastic.co/what-is/elasticsearch): Used for storing the final flow data. 

Sflow and netflow should be configured to send data to ports on the pipeline host (a different port for each sensor). Pmacct processes will be listening on those ports.

Tstat flow data can be sent directly to the ingest RabbitMQ queue on the pipeline host using the Netsage [tstat-transport](https://github.com/netsage-project/tstat-transport) tool. This can be installed as usual or via Docker. 

### Pipeline Installation

Originally, the pipeline was deployed by installing all of the components individually on one or more servers (the "BareMetal" or "Manual" Install). More recently, we've also added a Docker deployment option. For simple scenerios having just one sflow and/or one netflow sensor (and any number of tstat sensors), the basic "Docker Installation" should suffice. The "Docker Advanced Options" guide will help when there are more sensors and/or other customizations required.

## Visualization

[Grafana](https://grafana.com/oss/grafana/) or [Kibana](https://www.elastic.co/kibana) (with appropriate credentials) can be used to visualize the data stored in elasticsearch.  Netsage grafana dashboards are available in github [here](https://github.com/netsage-project/netsage-grafana-configs).


