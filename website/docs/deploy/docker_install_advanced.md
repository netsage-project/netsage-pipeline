---
id: docker_install_advanced
title: Docker Advanced Installation Guide
sidebar_label: Docker Advanced
---

## Dockerized Nfdump

If you wish to use dockerized version of the collectors, then there are three components to be aware of.

- collector docker container needs to run listening for sflow, or netflow traffic.
- an ENV value needs to be set that tags the sensor name.
- a unique data output path should be set.
- importer needs to be updated to be aware of the filepath and the sensor name.

### Step 1 Create a config

If you need to create more collectors the pattern is always the same. Simply add

```yaml
  uber-collector:
    image: netsage/nfdump-collector:1.6.18
    restart: always
    command: sfcapd -T all -l /data -S 1 -w -z -p 9998
    volumes:

      - ./data/input_data/sflow:/data

    ports:

      - "9998:9998/udp

```

- collector-name: should be updated to something that has some meaning.
- command: there are several binaries available in the collector, including: `nfanon, nfcapd,nfdump, nfexpire, nfreplay, sfcapd` . You'll need to choose between sfcapd and nfcapd which are two processes that collect data. Define a port that will be used to capture data.
- ports: make sure this matches the port you've defined. Naturally all ports have to be unique for that host.
- Configure routers to point to the UDP port we've exposed on the given host.
- define a sensor name to use. The value doesn't matter but it has to be unique and we'll make the importer aware of it.
- volumes: make sure the path where the data is going in unique. In this case, we're persisting data to ./data/input_data/sflow. The last part of the path is usually changed to some unique identifier.

We're going to build an example custom configuration. The only changes we'll be making right now is
to update the volums to this line.

```yaml
- ./data/input_data/uber_collector:/data
```

### Step 2 Create an unique environment variable

For this example I'm going to create a new env value in my .env file. I'm going to name my sensor uberSensor and then later make the importer aware of it.

```sh
uberSensor=magicValue
```

Also, if you are diverging from the default you will also need to create a custom importer configuration which will be stored at: /userConfig/netsage_override.xml. More will be explained under the importer custom section. Please uncomment the line in line under the importer in the override file.

### Step 3 Running the collectors

After selecting the docker version to run, you can start the collectors by running the following line:

```sh
docker-compose up -d uber-collector
```

Naturally the names of the services will need to be updated. Also if you haven't already done so you may remove any collectors you're not using from the override file (docker-compose.override.yml).

:::note
The default version of the collector is 1.6.18. There are other versions released and :latest should be point to the latest one, but there is no particular effort made to make sure we released the latest version. You can get a listing of all the current tags listed [here](https://hub.docker.com/r/netsage/nfdump-collector/tags) and the source to generate the docker image can be found [here](https://github.com/netsage-project/docker-nfdump-collector) the code for the You may use a different version though there is no particular effort to have an image for every nfdump release.
:::

## Running the Pipeline

Once you've created the docker-compose.override.xml and finished adjusting it for any customizations, then you're ready to select your version.

Before continuing you need to choose if you are going to be use the 'Develop' version which has the latest changes but might be a bit less stable or using the 'Release' version. If you're opting to use the Develop version, then simply skip the version selection step.

:::caution
Warning! it is HIGHLY recommended to not use the :latest as that is intended to be a developer release. You may still use it but be aware that you may have some instability each time you update.
:::

- Select Release version
  - `git fetch; git checkout <tag name>` replace "tag name" with v1.2.5 or the version you intend to use.
  - Please select the version you wish to use using `./scripts/docker_select_version.sh`

### Environment file

{@import ../components/docker_env.md}

### Custom Importer Config

The pipeline allows to have as many collectors as desired. You should have a unique sensorName ENV variable for each type and a unique path where data is being delivered.

By convention everything is being written to ./data/input_data/sensorName You may change that behavior but just ensure the path between the colle

1. Copy the compose/importer/netsage_shared.xml to userConfig/ and name it netsage_override.xml
2. In the docker-compose.yml uncomment the following line from the importer configuration.

```sh

      - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml

```

This will use the `netsage_override.xml` in the userConfig instead of the container settings.

3. Update collectors.

You may add as many new collectors as you like just ensure the following is unique:

```yml
example-collector:
  image: netsage/nfdump-collector:1.6.18
  command: nfcapd -T all -l /data -S 1 -w -z -p 9999
  ports:
    - "9999:9999/udp"

  restart: always
  volumes:
    - ./data/input_data/example:/data
```

- The command call should be updated. nfcapd for netflow, sfcapd for sflow
- The output under volumes needs to be unique. Replace /example with the appropriate value
- Make sure to update the port. The UDP port has to be unique. Please update the command and port mapping.

Technically you don't need to change to port of the command, but make sure you use the correct pattern when mapping the new settings.

Example:

```yml
ports:
  - "9999:4321/udp"
```

The first port is the port on your host, the second port is the port on your local machine.

4. Update the netsage_override.xml and add a new entry for the collector you're adding under the config section.

```xml
    <collection>
        <flow-path>/data/input_data/example</flow-path>
        <sensor>$exampleSensorName</sensor>
        <flow-type>sflow</flow-type>
    </collection>

```

5. Update the environment file.

```ini
exampleSensorName=example
```

6. At this point, please update the router configuration to send data to the new port you've defined. If the new collector is listening on 0.0.0.0:1234/udp then all traffic you wish grouped under

the new sensor should be send to 1234/udp.

You will need to repeat steps 3-6 for each collector you're adding. For each new configuration the path, sensorName and exposed port have to be unique. Besides that, there is no limit
outside of the bounds of the host's resources to how many collectors you may run.

### Customize Logstash Settings

Rename the provided example for JVM Options and tweak the settings as desired.

```sh
cp userConfig/jvm.options_example userConfig/jvm.options
```

Update the docker-compose.override.xml and ensure the logstash section is updated. It should look something along these lines.

```yaml
logstash:
  image: netsage/pipeline_logstash:latest
  volumes:
    - ./userConfig/jvm.options:/usr/share/logstash/config/jvm.options
```

### Kibana and Elastic Search

The file docker-compose.develop.yaml can be found in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker_dev_guide#optional-elasticsearch-and-kibana)

### Bringing up the Pipeline

{@import ../components/docker_pipeline.md}

## Upgrading

{@import ../components/docker_upgrade.md}
