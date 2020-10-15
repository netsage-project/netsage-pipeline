---
id: docker_install
title: Docker Installation Guide
sidebar_label: Docker Install
---

The docker pattern is provided as much simpler and easier to use pattern that allows you to process and send data without having to deal with all
the nuances of getting the pipeline setup.

Before we start, you may have a read over the [developer docker guide](../devel/docker) it contains several notes such as how to select the docker version and likely other bits of information you may find useful.

## Nfdump

Note that no matter if you use a localized version or take advantage of the docker container already built. You will need to configure your routers to send nfdump stats to the process collecting data on the host:port that you'll be defining.

More info of nfdump can be found [here](https://github.com/phaag/nfdump/)

### External Nfdump

In this case you have nfdump running in your network somewhere and would like to keep on using it rather then relying on the container provided.

You'll need to update your scripts to output to \$PROJECT/data/input_data. Naturally all the paths are configurable but you'll have a much easier if you stick to the defaults.

If you do choose to store the data elsewhere, the location may still need to be inside of the \$PROJECT or a docker volume location in order for docker to be able to reference it.

You will also need to configure your routers to point to the nfdump hostname and port in order for nfdump to collect data.

At this point please proceed to [Common Pattern](#common-pattern)

### Dockerized Nfdump

After you've selected the version of docker you'll be running. you can start the collector by simply running:

``` sh
docker-compose up -d collector
```

The default version is 1.6.18. There are other versions released and :latest should be point to the latest one, but there is no particular effort made to make sure we released the latest version. You can get a listing of all the current tags listed [here](https://hub.docker.com/r/netsage/nfdump-collector/tags) and the source to generate the docker image can be found [here](https://github.com/netsage-project/docker-nfdump-collector) the code for the You may use a different version though there is no particular effort to have an image for every nfdump release.

By default the container comes up and will write data to `./data/input_data` and listen to udp traffic on localhost:9999.

continue to [Common Pattern](#common-pattern)

## Common Pattern

Before continuing you need to choose if you are going to be use the 'Develop' version which has the latest changes but might be a bit less stable or using the 'Release' version.

* Development Version

  + Disregard anything about `docker_select_version.sh` that will not apply to you 
  + Update to latest code git pull origin master

* Release version
  + `git fetch; git checkout <tag name>` replace "tag name" with v1.2.5 or the version you intend to use.
  + Please select the version you wish to use using `./scripts/docker_select_version.sh`
it is HIGHLY recommended to not use the :latest as that is intended to be a developer release. You may still use it but be aware that you may have some instability each time you update.

### Environment file

Please make a copy of the .env and refer back to the docker [dev guide](../devel/docker) on details on configuring the env. Most of the default value should work just fine.

The only major change you should be aware of are the following values. The output host defines where the final data will land. The sensorName defines what the data will be labeled as.

If you don't send a sensor name it'll use the default docker hostname which changes each time you run the pipeline.

``` ini
rabbitmq_output_host=rabbit
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
rabbitmq_output_key=netsage_archive_input

sflowSensorName=sflowSensorName
netflowSensorName=netflowSensorName

```

Please note, the default is to have one netflow collector and one sflow collector.  If you need more collectors or do no need netflow or sflow simply comment out the collector you wish to ignore.

### Bringing up the Pipeline

Starting up the pipeline using:

``` sh
docker-compose up -d
```

You can check the logs for each of the container by running

``` sh
docker-compose logs
```

### Shutting Down the pipeline.

``` sh
docker-compose down
```

### Advanced Configuration

The pipeline allows to have as many collectors as desired.  You should have a unique sensorName ENV variable for each type and a unique path where data is being delivered.

By convention everything is being written to ./data/input_data/sensorName You may change that behavior but just ensure the path between the colle

1. Copy the compose/importer/netsage_shared.xml to userConfig/ and name it netsage_override.xml
2. In the docker-compose.yml uncomment the following line from the importer configuration.

``` sh

      - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml

```

This will use the `netsage_override.xml` in the userConfig instead of the container settings.

3. Update collectors.

You may add as many new collectors as you like just ensure the following is unique:

``` yml
  example-collector:
    image: netsage/nfdump-collector:1.6.18
    command: nfcapd -T all -l /data -S 1 -w -z -p 9999
    ports:

      - "9999:9999/udp"

    restart: always
    volumes:

      - ./data/input_data/example:/data

```

  + The command call should be updated.  nfcapd for netflow, sfcapd for sflow
  + The output under volumes needs to be unique. Replace /example with the appropriate value
  + Make sure to update the port.  The UDP port has to be unique.  Please update the command and port mapping.  

  Technically you don't need to change to port of the command, but make sure you use the correct pattern when mapping the new settings.

Example: 

``` yml
ports:

      - "9999:4321/udp"

```

The first port is the port on your host, the second port is the port on your local machine. 

4. Update the netsage_override.xml and add a new entry for the collector you're adding under the config section.

``` xml
    <collection>
        <flow-path>/data/input_data/example</flow-path>
        <sensor>$exampleSensorName</sensor> 
        <flow-type>sflow</flow-type>
    </collection>

```

5. Update the environment file.

``` ini
exampleSensorName=example
```

6. At this point, please update the router configuration to send data to the new port you've defined.  If the new collector is listening on 0.0.0.0:1234/udp then all traffic you wish grouped under 

the new sensor should be send to 1234/udp.  

You will need to repeat steps 3-6 for each collector you're adding.  For each new configuration the path, sensorName and exposed port have to be unique.  Besides that, there is no limit
outside of the bounds of the host's resources to how many collectors you may run.

### Kibana and Elastic Search

The file docker-compose.develop.yaml can be found in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker#optional-elasticsearch-and-kibana)

## Troubleshooting

### Data Flow issues:

**Troubleshooting checklist:**

  + Make sure you configured your routers to point to the correct address/port where the collector is running.  hostname:9999 is the default.
  + Make sure you created a .env file and updated the settings accordingly.
  + sensorName especially since that identifies the source of the data. 
  + check the logs of the various components to see if anything jumps out as being invalid.  docker-compose logs -f <service_label>

### Resource Limitations 

If you are running a lot of data sometimes docker may need to be allocated more memory.

Applying this snippet to logstash may help. Naturally the values will have to change.

``` yaml
environment:

  + LS_JAVA_OPTS=-Xmx3g

```

Alternatively you may also try doing this:

``` yaml
deploy:
  resources:
    limits:
      cpus: "0.50"
      memory: 50M
    reservations:
      cpus: "0.25"
      memory: 20M
```

Reference: https://docs.docker.com/compose/compose-file/#resources

## Upgrading

### Update Source Code

If your only changes are the version you selected simply reset and discard your changes.

``` 
git reset --hard
```

#### Development

Update the git repo. Likely this won't change anything but it's always a good practice to have the latest version. You will need to do at least a git fetch in order to see the latest tags.

``` 
git pull origin master
```

#### Release

  1. git checkout <tag_value> (ie. v1.2.6, v1.2.7 etc)
  2. `./scripts/docker_select_version.sh` select the same version as the tag you checked out.

### Update docker containers

This applies for both development and release

``` 
docker-compose pull
```
