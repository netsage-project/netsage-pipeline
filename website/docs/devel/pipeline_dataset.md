---
id: dev_dataset
title: Pipeline Replay Dataset
sidebar_label: Replay Dataset
---

The Netsage Pipeline processes network data.  Though there are some components and patterns we can use to test 
the behavior using things like the Ruby unit [tests](https://github.com/netsage-project/netsage-pipeline/tree/master/conf-logstash/ruby/spec) in logstash, and the [generator](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-generator.html) the best 
test is to replay network data and inspecting the output in the grafana dashboard. 

Two sample data set are provided for the two types of collectors we have (Netflow and Sflow).  The network data and ips have been annonymized and should have no identifying information. 

You can download the files locally from [here](https://drive.google.com/drive/folders/19fzY5EVoKwtYUaiBJq5OxAR82yDY0taG).

Please take note on which port the collectors are listing on.  You'll be running the collectors by using a custom docker-compose.override.yml but if you're using the example provided as baseline the ports should match this [example](https://github.com/netsage-project/netsage-pipeline/blob/master/docker-compose.override_example.yml). 

Currently the ports are:
  - 9999/udp for netflow.
  - 9998/udp for sflow and 

Naturally the collectors have to be running in order for any of this to be usable.  You can read more on how to get them running in the [Docker Simple Deployment Guide](../deploy/docker_install_simple.md#running-the-collectors)  

In order to replay the data use the following command for netflow/sflow respectively

### Netflow

```
nfreplay -H 127.0.0.1 -p 9999  -r nfcapd-ilight-anon-20200114 -v 9 -d 1000
```

### Sflow

```
nfreplay -H 127.0.0.1 -p 9998 -r sflow_anon.nfcapd -v 9 -d 1000
```

