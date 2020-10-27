---
id: pipeline
title: Pipeline
sidebar_label: Intro
---
# The NetSage Pipeline

# Description 

The Netsage Flow Processing Pipeline includes several components for processing network flow data, including importing, deidentification, metadata tagging, flow stitching, etc.

## Components

The Pipeline is made of the following components (currently)

 - [Sensor(s)]:  Network devices that collect flow data ([tstat](http://tstat.polito.it/), [sflow](https://www.rfc-editor.org/info/rfc3176), or [netflow](https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html)) and send it to a "pipeline host" for processing. Data may be sent to either a RabbitMQ queue or to a collector such as nfsen that writes it into nfcapd files on disk.
 - [Importer](https://github.com/netsage-project/netsage-pipeline/blob/master/lib/GRNOC/NetSage/Deidentifier/NetflowImporter.pm):  Perl scripts that read nfcapd files and send the flow data to a RabbitMQ queue.
      - [doc](pipeline_importer)
 - [RabbitMQ](https://www.rabbitmq.com/): Used for message passing and queuing of tasks.
 - [Logstash Pipeline](https://www.elastic.co/logstash): Performs a variety of transformations on the data.
     - [doc](pipeline_logstash) 
 - [Elasticsearch](https://www.elastic.co/what-is/elasticsearch): Used for storing the final flow data. 

## Running the Pipeline

There are many ways the pipeline can be set up and run. Deploying and configuring sensors will not be addressed here, other than to say that tstat flow data should be sent directly to the input RabbitMQ queue, while (currently) sflow and netflow data should be written to nfcapd files.  A Docker container for Tstat is available at https://github.com/netsage-project/tstat-transport/blob/master/docs/docker.md.

The original method to install the pipeline was to install all of the components individually on one or more servers (the "BareMetal" or "Server" Install). We've also added a Docker deployment option. With simple pipelines having just one sflow or netflow sensor, or one of each (and any number of tstat sensors), the "Docker Simple" Install should suffice. The "Docker Advanced" guide will help when there are more sensors and/or other customizations required.
 
