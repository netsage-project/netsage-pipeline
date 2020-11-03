---
id: intro
title: Intro
sidebar_label: Intro
---
# The NetSage Pipeline

## Description 

The Netsage Flow Processing Pipeline is composed of several components for processing network flow data, including importing, deidentification, metadata tagging, flow stitching, etc.
There are many ways the components can be combined, configured, and run. These documents will describe the standard "simple" set up and provide information for more complex configurations.

## Data Collection

In Netsage, sensor(s) are network devices configured to collect flow data ([tstat](http://tstat.polito.it/), [sflow](https://www.rfc-editor.org/info/rfc3176), or [netflow](https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html)) and send it to a "pipeline host" for processing. 

Tstat flow data can be sent directly to the ingest RabbitMQ queue using the Netsage [tstat-transport](https://github.com/netsage-project/tstat-transport) tool. This can be installed as usual or via Docker. 

Sflow and netflow data from configured routers can be collected and stored into nfcapd files using [nfdump tools](https://github.com/phaag/nfdump). The Netsage project has packaged the nfdump tools into a [Docker container](https://github.com/netsage-project/docker-nfdump-collector) for ease of use.

## Pipeline Components

The Netsage Flow Processing Pipeline is made of the following components (currently)

 - [Importer]:  Perl scripts on the pipeline host that read nfcapd flow files and send the flow data to a RabbitMQ queue.  - [doc](importer.md) - [on github](https://github.com/netsage-project/netsage-pipeline/blob/master/lib/GRNOC/NetSage/Deidentifier/NetflowImporter.pm)
 - [RabbitMQ](https://www.rabbitmq.com/): Used for message passing and queuing of tasks.
 - [Logstash Pipeline](https://www.elastic.co/logstash): Performs a variety of operations on the flow data to transform it and add additional information.  - [doc](logstash.md) 
 - [Elasticsearch](https://www.elastic.co/what-is/elasticsearch): Used for storing the final flow data. 

## Visualization

[Grafana Dashboards](https://grafana.com/oss/grafana/) are used to visualize the data stored in elasticsearch.  - [Netsage Dashboards on github](https://github.com/netsage-project/netsage-grafana-configs)

## Pipeline Installation

Originally, the pipeline was deployed by installing all of the components individually on one or more servers (the "BareMetal" or "Server" Install). More recently, we've also added a Docker deployment option. With simple pipelines having just one sflow or netflow sensor, or one of each (and any number of tstat sensors), the "Docker Simple" Install should suffice. The "Docker Advanced" guide will help when there are more sensors and/or other customizations required.

