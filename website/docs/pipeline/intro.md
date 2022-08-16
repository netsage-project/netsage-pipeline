---
id: intro
title: Intro
sidebar_label: Intro
---
## Network Flows

As is well known, communication between two computers is accomplished by breaking up the information to be sent into packets which are forwarded through routers and switches from the source to the destination. A **flow** is defined as a series of packets with common characteristics. Normally these are the source IP and port, the destination IP and port, and the protocal (the **5-tuple**). These flows can be detected and analyzed to learn about the traffic going over a certain circuit, for example. 

> Note that when there is a "conversation" between two hosts, there will be two flows, one in each direction. Note also that determining when the flow ends is somewhat problematic. A flow ends when no more matching packets have been detected for some time, but exactly how much time? A router may declare a flow over after waiting just 15 seconds, but if one is interested in whole "conversations," a much longer time might make more sense. The source port of flows is normally ephemeral and a particular value is unlikely to be reused in a short time unless the packets are part of the same flow, but what if packets with the same 5-tuple show up after 5 or 10 or 30 minutes? Are they part of the same flow? 

## Flow Export

Network devices such as routers can function as **flow exporters** by simply configuring and enabling flow collection. All or nearly all come with this capability. 

There are three main types of flow exporters: **[sflow](https://www.rfc-editor.org/info/rfc3176)**, **[netflow/IPFIX](https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html))** and **[tstat](http://tstat.polito.it/)**. Sflow data is composed of sampled packets, while netflow (the newest version of which is IPFIX) and tstat data consists of information about series of packets (ie whole flows, or what they consider whole flows). These are described further in the following sections. 

For Netsage, flow exporters, also referred to as **sensors**, are configured to send the flow data to a **Netsage Pipeline host** for processing. 

## The NetSage Pipeline

The **Netsage Flow Processing Pipeline** processes network flow data. It is comprised of several components that collect the flows, add metadata, stitch them into longer flows, etc.

### Pipeline Components

The Netsage Flow Processing Pipeline is made of the following components

 - **[Pmacct](https://github.com/pmacct/pmacct)**: The pmacct package includes sfacctd and nfacctd daemons which receive sflow and netflow/IPFIX flows, respectively. They are configured to send the flows to a rabbitMQ queue.
 - **[RabbitMQ](https://www.rabbitmq.com/)**: RabbitMQ is used for message queueing and passing at a couple of points in the full pipeline.
 - **[Logstash](https://www.elastic.co/logstash)**: Our logstash pipeline pulls flow data from a rabbitMQ queue and performs a variety of operations to transform it and add additional information.  
 - **[Elasticsearch](https://www.elastic.co/what-is/elasticsearch)**: Elasticsearch is used for storing the final flow data. 

### Pipeline Installation

Originally, the pipeline was deployed by installing all of the components individually on one or more servers (the "Bare Metal" or "Manual" Install). We still use this deployment method at IU. More recently, we've also added a Docker deployment option. For simple scenerios having just one sflow and/or one netflow sensor (and any number of tstat sensors), the basic "Docker Installation" should suffice. The "Docker Advanced Options" guide will help when there are more sensors and/or other customizations required.

## Visualization

[Grafana](https://grafana.com/oss/grafana/) or [Kibana](https://www.elastic.co/kibana) (with appropriate credentials) can be used to visualize the data stored in elasticsearch.  Netsage grafana dashboards or **portals** are set up by the IU team.  The dashboards are saved in github [HERE](https://github.com/netsage-project/netsage-grafana-configs).


