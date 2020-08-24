---
id: new_collector
title: New Collector
sidebar_label: New Collector
---
The [netsage-flow-collector](https://github.com/netsage-project/netsage-flow-collectors) project is intended to facilitate the data collection of various types of flows and deliver the data to a message queue.  It is replacing the [Importer](importer.md) and the nfdump-collector tooling.  Unlike the Importer the New Collector will directly write the messages to rabbitMQ. 

Currently utilizing RabbitMQ but any message queue that [pmacct](https://github.com/pmacct/pmacct) can use would work.


## Installation

### Getting the Code

:::note
Please checkout the flow-collector code a different location than the pipeline and follow the instructions as outlined
:::

```sh
cd ..  ##only if starting from the pipeline repo 
git clone https://github.com/netsage-project/netsage-flow-collectors.git
```


### Installation Notes:

You can run this via a docker stack (recommended) or using a baremetal install.  For baremetal install please see the documentation in the flow project [here](https://github.com/netsage-project/netsage-flow-collectors/blob/feature/template/docs/03_baremetal.md).

These directions will focus on the docker flow.

Install the dependencies:

```sh
pip install -r requirements.txt
```

copy the default configuration and update according to your environment.

```sh
cp gen_config/collectors.template.yml  gen_config/collectors.yml 
```

The default is for the configuration to be created under `deploy` folder.  It'll create two sensors.


The default behavior is to support 1 netflow and 1 sflow collector.  We're assuming you'll be running in production mode.

To add additional sensors simple add a new block similar to:

<details><summary>Example Sensor</summary>
<p>


```yaml
  - sensorName: superCool ## unique
    enabled: True
    type: sflow
    instanceID: 0  ## must be numeric
    port: 9997  ## unique
```

</p>

</details>

<p>&nbsp; </p>

:::note
The default, configuration is running on alternative ports so they won't clash with the importer.  If you'd like you can make them match the importer port but you'll need to disable the importer and related collectors
:::

For Developers please consider setting include_dev_generate and include_dev_queue to true.

  * include_dev_generate: Enables iperf3 tooling to generate dummy sflow traffic.
  * include_dev_queue: will create a local RabbitMQ instance rather then relying on the pipeline project.

## Running container

Assuming default configuration, the files are all created in the `deploy` folder.  We'll assume you're inside that directory to issue any of these commands.

```sh
## Bringing up container
docker-compose up -d 
## Viewing logs
docker-compose logs -f 
```

Once the collector is up, you'll need to configure the appropriate routers to send metrics 
to the appropriate ip/port combination via UDP.

## Disabling Legacy Collectors

It is easier to just let the collectors run since they won't be doing anything but if you find a need to disable the legacy importers, here are the steps involved.

- **docker-compose.yml**: Remove the `importer` target and all related data.
- **docker-compose.override.yml**: Remove the `importer`, `sflow-collector` and `netflow-collector`. 