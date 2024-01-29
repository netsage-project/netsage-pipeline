---
id: docker_dev_guide
title: Docker Dev Guide
sidebar_label: Docker Dev Guide
---

## Selecting a Version

You can use the "master" version or a tagged version.  
To select a released version use the docker_select_version.sh script (see the Deployment Guide).
If you wish to use the development version (master branch) simply skip the docker_select_version.sh step.

## Installing

See the Deployment Guide to learn how to set up collectors, your environment and override files, etc.

## Importer 

The importer "shared" config that Docker uses is defined in compose/netsage_shared.xml.  ** NOTE: If you want to make changes to this file, you will need to rebuild the container**

## Build Images 

The images are published on Docker Hub, but if you'd like to incorporate local changes please follow the process below.

### Build Using Source Code

If you would like to build the *importer* container using the version of the pipeline scripts found in the GitHub repo then run the following:

```sh 
docker-compose -f docker-compose.build.yml build

```

NOTE: The importer container includes the config files for the logstash pipeline. 


## Optional: ElasticSearch and Kibana

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

## Handy Docker Commands

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
