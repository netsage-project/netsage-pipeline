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
