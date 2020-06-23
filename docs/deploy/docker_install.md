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

```sh
docker-compose up -d collector
```

The default version is 1.6.18. There are other versions released and :latest should be point to the latest one, but there is no particular effort made to make sure we released the latest version. You can get a listing of all the current tags listed [here](https://hub.docker.com/r/netsage/nfdump-collector/tags) and the source to generate the docker image can be found [here](https://github.com/netsage-project/docker-nfdump-collector) the code for the You may use a different version though there is no particular effort to have an image for every nfdump release.

By default the container comes up and will write data to `./data/input_data` and listen to udp traffic on localhost:9999.

continue to [Common Pattern](#common-pattern)

## Common Pattern

Please select the version you wish to use using `./scripts/docker_select_version.sh`. We recommend not using the :latest as that is intended to be a developer release. You may still use it but be aware that you may have some unstability each time you update.

### Environment file

Please make a copy of the .env and refer back to the docker [dev guide](../devel/docker) on details on configuring the env. Most of the default value should work just fine.

The only major change you should be aware of are the following values. The output host defines where the final data will land. The sensorName defines what the data will be labeled as.

If you don't send a sensor name it'll use the default docker hostname which changes each time you run the pipeline.

```ini
rabbitmq_output_host=rabbit
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
rabbitmq_output_key=netsage_archive_input

sensorName=bestSensorEver

```

### Bringing up the Pipeline

Starting up the pipeline using:

```sh
docker-compose up -d
```

You can check the logs for each of the container by running

```sh
docker-compose logs
```

### Shutting Down the pipeline.

```sh
docker-compose down
```

### Kibana and Elastic Search

The file docker-compose.develop.yaml can be found in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker#optional-elasticsearch-and-kibana)

## Troubleshooting

If you are running a lot of data sometimes docker may need to be allocated more memory.

Applying this snippet to logstash may help. Naturally the values will have to change.

```yaml
environment:
  - LS_JAVA_OPTS=-Xmx3g
```

Alternatively you may also try doing this:

```yaml
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

### Update Git

If your only changes are the version you selected simply reset and discard your changes.

```
git reset --hard
```

Update the git repo. Likely this won't change anything but it's always a good practice to have the latest version. You will need to do at least a git fetch in order to see the latest tags.

```
git pull origin master
```

### Update docker containers

Select the version to use via `./scripts/docker_select_version.sh` or if you are using the devel simply run:

```
docker-compose pull
```
