---
id: docker_dev_guide
title: Docker Dev Guide
sidebar_label: Docker Dev Guide
---

# Docker Setup

## Configure Collectors

Before you start if you haven't already done so, please make a copy of docker-compose.override_example.yml this is used to setup your collectors.  The default should work out of the box with the env.example provided.  If you wish you add customizations, please see the [Docker Advanced Install Guide](../deploy/docker_install_advanced.md)

``` sh
cp docker-compose.override_example.yml docker-compose.override.yml
```

## Selecting a Version

We currently release a development version and a tagged version.  The first version to support will be. v1.2.5 once release.  

### Stable Release Version

To select a released version please do the following.

``` sh
 scripts/docker_select_version.sh tagValue 
 ```

Example:

``` sh 
scripts/docker_select_version.sh v1.2.5 

``` 
If you run the script without any version specified it'll list all the current tags and prompt you to select a version.

Once that's complete, all the instructions below are still applicable. 

### Development Version

If you wish to use the development version you are free to do so.  It is the default behavior on 
any git checkout.  Simply follow the directions below and setup your pipeline as instructed.

## Build Base Images 

This is optional.  The image are published on docker hub, but if you'd like to incorporate local changes please follow the process below.

### Build Using Source Code

If you would like to build the *importer* container using the version of the pipeline scripts found in this GitHub repo then run the following:

```sh 
docker-compose -f docker-compose.build.yml build

```

## Configuring the Containers

### Environment File

If you haven't done so already, copy env.example and update it to match your own settings:

``` sh
cp env.example .env
```

### Rabbit 

This portion is primarily to set the Rabbit MQ server.  Most of the default settings work but whatever values you set
here should be consistent with the config for the logstash and importer 

``` sh
RABBITMQ_ERLANG_COOKIE='secret cookie'
RABBIT_HOST=rabbit
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
discovery.type=single-node
```

Note the hostname will follow the docker-compose label.  You can rename it if you like but by default it's set to rabbit

### Importer 

The importer config is defined in compose/netsage_shared.xml.  If you use different values then the defaults you may want to change them/ **NOTE: Changes will require you to rebuild the container**

### Logstash 

Define the input rabbit queue.  This should match the importer output queue

``` sh
rabbitmq_input_host=rabbit
rabbitmq_input_username=guest
rabbitmq_input_pw=guest

```

Define the output rabbit queue.  This can be the docker container or any valid RabbitMQ server.

``` sh
rabbitmq_output_host=rabbit
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
rabbitmq_output_key=netsage_archive_input
```

### Optional: ElasticSearch and Kibana

You can optionally store flow data locally in an ElasticSearch container and view the data with Kibana. Local storage can be enabled with the following steps:

1.  Uncomment the following lines in conf-logstash/99-outputs.conf:

``` 
elasticsearch {
    hosts => ["elasticsearch"]
    index => "netsage_flow-%{+YYYY.MM.dd}"
}
```

2. Comment out the `rabbitmq {...}` block in conf-logstash/99-outputs.conf if you do not want to also send logstash output to RabbitMQ.

3.  Run the containers using the following line: ` `  ` docker-compose -f docker-compose.yml  -f docker-compose.develop.yml up  -d `  ` `

## Running the Containers

### Start the Containers

``` sh
docker-compose up -d 
```

### Stop the Containers

``` sh
docker-compose stop && docker-compose rm 
```

### Enter a Container Shell

``` sh
docker-compose exec logstash bash     #bash shell in logstash container
docker-compose exec importer bash     #bash shell in importer container
docker-compose exec rabbit bash       #bash shell in rabbit container
```

### View Container Logs

``` sh
docker-compose logs -f              #view logs for all containers 
docker-compose logs -f logstash     #view logs for logstash container
docker-compose logs -f importer     #view logs for importer container
docker-compose logs -f rabbit       #view logs for rabbit container
```
