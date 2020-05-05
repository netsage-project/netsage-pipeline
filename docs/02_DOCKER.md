---
id: docker
title: Docker Guide
sidebar_label: Docker Guide
---
# Docker Setup

## Retrieve Enrichment Metadata

Run the following to download Science Registry and GeoIp data. You may re-run this at anytime to update these databases.

```sh
./initialize_docker_data.sh
```

## Build Base Images

### Build Using Source Code
If you would like to build the *importer* container using the version of the pipeline scripts found in this GitHub repo then run the following:

```sh 
docker-compose -f docker-compose.build.yml build
```

### Build Using Production RPM Release 
You may also build the *importer* container using the RPM published in a remote GRNOC yum repo as opposed to your local copy of this source code. **NOTE: The published RPM may install a version of the importer scripts different from what is found in your local copy of this GitHub repository depending on when the RPM was last built and uploaded.**

1. Copy the env.example file to .env
```sh
cp env.example .env
```

2. Add this entry:
```sh
RELEASE=true
```

3. Build the containers

```sh 
docker-compose -f docker-compose.build.yml build
```

## Configuring the Containers

### Environment File

If you haven't done so already, copy env.example and update it to match your own settings:
```sh
cp env.example .env
```

### Rabbit 
This portion is primarily to set the Rabbit MQ server.  Most of the default settings work but whatever values you set
here should be consistent with the config for the logstash and importer 

```sh
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

```sh
rabbitmq_input_host=rabbit
rabbitmq_input_username=guest
rabbitmq_input_pw=guest

```

Define the output rabbit queue.  This can be the docker container or any valid RabbitMQ server.

```sh
rabbitmq_output_host=rabbit
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
rabbitmq_output_key=netsage_archive_input
```

### Optional: ElasticSearch and Kibana
You can optionally store flow data locally in an ElasticSearch container and view the data with Kibana. Local storage can be enabled with the following steps:

1.  Uncomment the elasticsearch and kibana services in docker-compose.yml. 

2.  Uncomment the following lines in conf-logstash/99-outputs.conf:

```
elasticsearch {
    hosts => ["elasticsearch"]
    index => "netsage_flow-%{+YYYY.MM.dd}"
}
```

3. Comment out the `rabbitmq {...}` block in conf-logstash/99-outputs.conf if you do not want to also send logstash output to RabbitMQ.

## Running the Containers

### Start the Containers
```sh
docker-compose up -d 
```

### Stop the Containers
```sh
docker-compose down
```
### Enter a Container Shell
```sh
docker-compose exec logstash bash     #bash shell in logstash container
docker-compose exec importer bash     #bash shell in importer container
docker-compose exec rabbit bash       #bash shell in rabbit container
```

### View Container Logs
```sh
docker-compose logs -f              #view logs for all containers 
docker-compose logs -f logstash     #view logs for logstash container
docker-compose logs -f importer     #view logs for importer container
docker-compose logs -f rabbit       #view logs for rabbit container
```

