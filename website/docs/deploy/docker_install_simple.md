---
id: docker_install_simple
title: Docker Default Installation Guide
sidebar_label: Docker Simple
---

## Dockerized Nfdump

If you wish to use dockerized version of the collectors, then there are three components to be aware of.

- collector docker container needs to run listening for sflow, or netflow traffic.
- an ENV value needs to be set that tags the sensor name.
- a unique data output path should be set.
- importer needs to be updated to be aware of the filepath and the sensor name.

### Step 1 Create a config

The default pattern is defined in the docker-compose.override_example.yml. By default we bring up a single netflow collector and a single sflow collector. For most people this is more than enough. You may wish to delete collectors you're not using.

```sh
cp docker-compose.override_example.yml docker-compose.override.yml
```

If you're sticking to the default you don't need to make any changes to the docker-compose.override_example.yml

:::note
You may need to remove all the comments in the override file as they may conflict with the parsing done by docker-compose
:::

:::note
If you are only interested in netflow or sflow data, you may want to remove the collector configuration that is not used.
:::

### Step 2 Create an unique environment variable

default value are set in the .env default to

```sh
sflowSensorName=sflowSensorName
netflowSensorName=netflowSensorName
```

simply change the names to a unique identifier and you're good to go.

These names uniquely identify the source of the data. If you're not using the netflow or sflow collector, then simply disregard the env settings.

### Running the collectors

After selecting the docker version to run, you can start the collectors by running the following line

```sh
docker-compose up -d sflow-collector netflow-collector
```

By default the container comes up and will write data to `./data/input_data` . Each collector is namespaced by its type so sflow collector will write data to `./data/input_data/slow` , it's sensor name is: sflowSensorName and listen to udp traffic on localhost:9999.

## Running the Pipeline

Once you've created the docker-compose.override.xml and finished adjusting it for any customizations, then you're ready to select your version.

- Select Release version
  - `git fetch; git checkout <tag name>` replace "tag name" with v1.2.5 or the version you intend to use.
  - Please select the version you wish to use using `./scripts/docker_select_version.sh`

### Environment file

{@import ../components/docker_env.md}

### Bringing up the Pipeline

{@import ../components/docker_pipeline.md}

## Upgrading

{@import ../components/docker_upgrade.md}
