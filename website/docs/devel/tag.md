---
id: docker_dev_tag
title: How to Release a New Version of the Pipeline
sidebar_label: Making Releases
---

If a new version of nfdump needs to be used, make the new nfdump-collector image(s) first (see below) and update the docker-compose files with the new version number, then make new pipeline_importer and pipeline_logstash images..

## Make an RPM Release 

Use standard procedures to create an rpm of the new version of the pipeline. Update the version number and the CHANGES file, build the rpm, repoify, etc., then upgrade grnoc-netsage-deidentifier on bare-metal hosts using yum. If all works well, do the following steps to create new Docker images with which to upgrade Docker deployments.

## In Github, Create a Release Tag

Create a new Tag or Release in Github, eg, v1.2.11.
Be sure to copy info from the CHANGES file into the Release description.

## To Build and Push Images Manually

Below is the procedure to build pipeline_importer and pipeline_logstash images manually.

Install docker-compose if not done already. See the Docker Installation instructions.

Git clone (or git pull) the pipeline project and check out the tag you want to build, then set the version number in docker-compose.build.yml using the script. Eg, for v1.2.11,
```
git clone https://github.com/netsage-project/netsage-pipeline.git
cd netsage-pipeline
git checkout -b v1.2.11
./scripts/docker_select_version.sh 1.2.11
```

Then build the pipeline_importer and pipeline_logstash images and push them to Docker Hub:
```
$ sudo systemctl start docker
$ sudo docker-compose -f docker-compose.build.yml build
$ sudo docker login
     provide your DockerHub login credentials
$ sudo docker-compose -f docker-compose.build.yml push    (will push images mentioned in docker-compose.yml ??)
     or  $ docker push $image:$tag                        (will push a specific image version)
$ sudo systemctl stop docker
```
If you run into an error about retrieving a mirrorlist and could not find a valid baseurl for repo, restart docker and try again.
If that doesn't work, try adding this to /etc/hosts: `67.219.148.138  mirrorlist.centos.org`, and/or try `yum install net-tools bridge-utils`, and/or restart network.service then docker. 

The person pushing to Docker Hub must have a Docker Hub account and belong to the Netsage team (3 users are allowed, for the free level).

It might be a good idea to test the images before pushing them. See "Test Docker Images" below.


## Building With Automation

???

## Test Docker Images 

See the Docker installation instructions for details... 

In the git checkout of the correct version, make an .env file and a docker-compose.override.yml file. You probably want to send the processed data to a dev Elasticsearch instance. Use samplicate or some other method to have data sent to the dev host. 

Run docker_select_version.sh if you haven't already, then start it up `$ sudo docker-compose up -d`. If there are local images, they'll be used, otherwise they'll be pulled from Docker Hub.

After about 30 minutes, you should see flows in elasticsearch.

## Make Versioned Docs

A new set of versioned docs also has to be tagged once you are done making changes for the latest pipeline version. See the **Docusaurus guide**. 

## To Make New Nfdump-Collector Images

If a new version of nfdump has been released that we need, new nfdump-collector images need to be made.

```
$ git clone https://github.com/netsage-project/docker-nfdump-collector.git
$ cd docker-nfdump-collector
$ sudo systemctl start docker
```

To use squash: create a file at /etc/docker/daemon.json and put into it
```
 "experimental": true  
 "debug: false"
```

To build version $VER, eg, 1.6.23 (both regular and alpine linux versions ?):
```
$ sudo docker build --build-arg NFDUMP_VERSION=$VER  --tag netsage/nfdump-collector:$VER --squash  collector
$ sudo docker build --build-arg NFDUMP_VERSION=$VER  --tag netsage/nfdump-collector:alpine-$VER -f collector/Dockerfile-alpine --squash .    
```

To push to Docker Hub and quit docker
```
$ sudo docker login
     provide your DockerHub login credentials
$ sudo docker push netsage/nfdump-collector:$VER
$ sudo systemctl stop docker
```

To use the new collector image in the pipeline, change the version number in docker-compose.override_example.yml. For example, to use the alpine-1.6.23 image:
```
sflow-collector:
    image: netsage/nfdump-collector:alpine-1.6.23
...
netflow-collector:
    image: netsage/nfdump-collector:alpine-1.6.23
```

Remind users to make the same change in their docker-compose.override.yml file when they do the next pipeline upgrade.


### New Version of Logstash

If a new version of logstash has been released that we want everyone to use,
???
