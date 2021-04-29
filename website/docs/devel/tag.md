---
id: docker_dev_tag
title: Tagging a Release
sidebar_label: How to Tag a New Release
---

To tag a new release, first updated the version number and Changes file, build the rpm, etc.  and upgrade on bare-metal hosts using yum. If all works fine, do the following steps to create new Docker images.

## In Github, Create a Release/Tag

Be sure to copy info from the Changes file into the Release description.

Do this first ???

## To Build and Push an Importer Image Manually

Git clone the pipeline project and have the ?? branch checked out. 

```
$ docker-compose build
$ docker login
$ docker push $image:$tag
```

This will build the image and push it to Docker Hub.

The person doing this has to have a Docker Hub account and belong to the Netsage team (3 users are allowed, for the free level).

## With Automation


## Versioned Docs

A new set of versioned docs also has to be tagged. See the Docusaurus guide. 

Does this have to happen before Building the image ??

## New Version of Nfdump

If a new version of dfdump has been released that we need,
????

## New Version of Logstash

If a new version of logstash has been released that we want everyone to use,
???
