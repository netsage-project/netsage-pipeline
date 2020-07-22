---
id: pipeline
title: Pipeline
sidebar_label: Intro
---
import useBaseUrl from '@docusaurus/useBaseUrl'; 

# The NetSage Pipeline

<a href={useBaseUrl('img/dataflow.jpg')}>
<img alt="DataFlow Diagram" src={useBaseUrl('img/dataflow.jpg')} />
</a>

# Description 

The Netsage Flow Processing Pipeline includes several components for processing network flow data, including importing, deidentification, metadata tagging, flow stitching, etc.

## Components

The Pipeline is made of the following components (Currently)

 - [Importer](https://github.com/netsage-project/netsage-pipeline/blob/master/lib/GRNOC/NetSage/Deidentifier/NetflowImporter.pm)  (Collection of perl scripts)

      - [doc](pipeline_importer)

 - [Elastic Logstash](https://www.elastic.co/logstash) Performs a variety of transformation on the data

     - [doc](pipeline_logstash) 

 - [RabbitMQ](https://www.rabbitmq.com/) used for message passing and queing of tasks.

## Sensors and Data Collection

"Testpoints" or "sensors" collect flow data ([tstat](http://tstat.polito.it/), [sflow](https://www.rfc-editor.org/info/rfc3176), or [netflow](https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html)) and send it to a "pipeline host" for processing (for globanoc, flow-proc.bldc.grnoc.iu.edu or netsage-probe1.grnoc.iu.edu). 

Tstat data goes directly into the netsage_deidentifier_raw queue rabbit queue. The other data is written to nfcapd files.

### Importer 

A netsage-netflow-importer-daemon reads any new nfcapd files that have come in after a configurable delay. The importer aggregates flows within each file, and writes the results to the netsage_deidentifier_raw queue rabbit queue.
