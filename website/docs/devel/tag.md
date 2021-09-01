---
id: docker_dev_tag
title: How to Do a New Docker-Pipeline Release
sidebar_label: New Docker Release
---

To make a new release, first update the version number and CHANGES file, build the rpm, etc.  and upgrade on bare-metal hosts using yum. If all works fine, do the following steps to create new Docker images with which to upgrade Docker deployments.

## In Github, Create a Release Tag

Be sure to copy info from the Changes file into the Release description.

## To Build and Push an Importer Image Manually

Install docker-compose if not done already. See the Docker Installation instructions.

Git clone (or git pull) the pipeline project and check out the tag branch, and set the version number in docker-compose.build.yml using the script. Eg, for v1.2.11,
```
git clone https://github.com/netsage-project/netsage-pipeline.git
cd netsage-pipeline
git checkout v1.2.11
./scripts/docker_select_version.sh 1.2.11
```

This will then build the importer and pipeline_logstash images and push them to Docker Hub:
```
$ sudo systemctl start docker
$ sudo docker-compose -f dcoker-cmpose.build.yml build
$ sudo docker login
     provide your DockerHub login credentials
$ docker push $image:$tag
```
The person doing this has to have a Docker Hub account and belong to the Netsage team (3 users are allowed, for the free level).

## With Automation

???

## Versioned Docs

A new set of versioned docs also has to be tagged. See the Docusaurus guide. 

I don't think this has to happen before Building the image 

## New Version of Nfdump

If a new version of nfdump has been released that we need,
????

## New Version of Logstash

If a new version of logstash has been released that we want everyone to use,
???
