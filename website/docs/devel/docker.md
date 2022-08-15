---
id: docker_dev_guide
title: Docker Dev Guide
sidebar_label: Docker Dev Guide
---
## Handy Docker Commands

### Start the Containers

``` sh
docker-compose up -d 
```

### Stop the Containers

``` sh
docker-compose down
docker-compose stop && docker-compose rm 
```

### Enter a Container Shell

``` sh
docker-compose exec logstash bash     # run bash shell in logstash container
```

### View Container Logs

``` sh
docker-compose logs -f              # view logs for all containers 
docker-compose logs -f <container>  # view logs for container, eg logstash
```

## To Build Docker Images 

We will normally use official images for rabbitMQ, logstash, nfacctd, and sfacctd, so no building of images is required.

However, in case there is not an offical image of nfacctd or sfacctd that includes required commits, you may need to build images from master.

Below are the steps used to build the Docker images for v2.0. In the future, you may not have to apply a patch. (Without the patch, when bringing up the nfacctd or sfacctd container, we got *error while loading shared libraries: libndpi.so.4: cannot open shared object file: No such file or directory*.)

The nfacctd and sfacctd images are just the base image plus specific commands to run. 

```
You may need to add dns servers from /etc/resolv.conf to /etc/docker/daemon.json and restart docker
$ git clone https://github.com/pmacct/pmacct.git
$ mv pmacct pmacct-30June2022+patch
$ cd pmacct-30June2022/
$ git checkout 865a81e1f6c444aab32110a87d72005145fd6f74
$ git submodule update --init --recursive
$ git am -3 0001-ci-docker-fix-docker-multi-stage-build.patch
$ sudo docker build -f docker/base/Dockerfile -t pmacct:base .
$ sudo docker tag  pmacct:base  base:_build
$ sudo docker build -f docker/nfacctd/Dockerfile -t nfacctd:7Jun2022 .
$ sudo docker build -f docker/nfacctd/Dockerfile -t sfacctd:7Jun2022 .  

$ sudo docker-compose up -d
$ sudo docker-cmopose down
```

These steps checkout the code from the desired point in time, get files for submodules, apply the patch that was emailed and saved to ~/lensman/GIT/pmacct-30June2022+patch/0001-ci-docker-fix-docker-multi-stage-build.patch on netsage-pipeline-dev2.bldc, build the base image, rename the base image, build nfacctd and sfacctd images. After building, do a test run (of course, first make the .env file, etc.). When ready, push to the Github Container Registry.


## To push images to the GitHub Container Registry
You need to have a personal access token and (presumably) be part of the Netsage Project. The personal access token needs at least the following scopes:  repo, read/write/delete:packages. 

As an example, here is how lisaens pushed the images for 2.0:
```
$ sudo docker login ghcr.io -u lisaens 
$ sudo docker images  (to get the id)
  REPOSITORY                            TAG              IMAGE ID       CREATED        SIZE
  sfacctd                               7Jun2022         f62b1c6cddbd   5 weeks ago    346MB
  nfacctd                               7Jun2022         5833977f6dd0   5 weeks ago    346MB
$ sudo docker tag f62b1c6cddbd ghcr.io/netsage-project/sfacctd:7Jun2022
$ sudo docker push ghcr.io/netsage-project/sfacctd:7Jun2022
$ sudo docker tag 5833977f6dd0 ghcr.io/netsage-project/nfacctd:7Jun2022
$ sudo docker push ghcr.io/netsage-project/nfacctd:7Jun2022
Go to the Netsage Project in github (netsage-project), click on Packages, click on an image, click on Connect to Repository and select Netsage Pipeline,
then go to Package Settings (lower right). In the Danger Zone, click on Change Visibility and choose Public.
```

NOTE that the docker-compose.yml file must refer to the images using the registry location, eg, for sfacctd  `ghcr.io/netsage-project/sfacctd:7jun2022`.


## Run ElasticSearch and Kibana Containers

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

