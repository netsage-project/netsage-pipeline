---
id: intro
title: Intro
sidebar_label: Intro
---
# The NetSage Pipeline

## Description 

The Netsage Flow Processing Pipeline is composed of several components for processing network flow data, including importing, deidentification, metadata tagging, flow stitching, etc.
There are many ways the components can be combined, configured, and run. These documents will describe the standard "simple" set up and provide information for more complex configurations.

## Components

The Pipeline is made of the following components (currently)

 - Sensor(s):  Network devices configured to collect flow data ([tstat](http://tstat.polito.it/), [sflow](https://www.rfc-editor.org/info/rfc3176), or [netflow](https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html)) and send it to a "pipeline host" for processing. 
 - [Importer](https://github.com/netsage-project/netsage-pipeline/blob/master/lib/GRNOC/NetSage/Deidentifier/NetflowImporter.pm):  Perl scripts on the pipeline host that read nfcapd files and send the flow data to a RabbitMQ queue.
     - [doc](importer)
 - [RabbitMQ](https://www.rabbitmq.com/): Used for message passing and queuing of tasks.
 - [Logstash Pipeline](https://www.elastic.co/logstash): Performs a variety of operations on the flow data to transform it and add additional information.
     - [doc](logstash) 
 - [Elasticsearch](https://www.elastic.co/what-is/elasticsearch): Used for storing the final flow data. 
 - [Grafana Dashboards](https://github.com/netsage-project/netsage-grafana-configs) are used to visualize the data stored in elasticsearch.

## Data Collection

Tstat flow data can be sent directly to the ingest RabbitMQ queue using the Netsage [tstat-transport](https://github.com/netsage-project/tstat-transport) tool. This can be installed as usual or via Docker. 
 - [doc](tstat) 

Incoming sflow and netflow data from configured routers can be collected and stored into nfcapd files using [nfdump tools](https://github.com/phaag/nfdump). The Netsage project has packaged the nfdump tools into a [Docker container](https://github.com/netsage-project/docker-nfdump-collector) for ease of use.
 - [doc](nfdump)

## Installation

The original method to install the pipeline was to install all of the components individually on one or more servers (the "BareMetal" or "Server" Install). We've also added a Docker deployment option. With simple pipelines having just one sflow or netflow sensor, or one of each (and any number of tstat sensors), the "Docker Simple" Install should suffice. The "Docker Advanced" guide will help when there are more sensors and/or other customizations required.

