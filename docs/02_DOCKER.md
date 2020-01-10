# Docker Setup

## Retrieve Meta data.  Feel free to re-run  to update the data.  Set the correct username/password to match your credentials.

SCIENCE_USER='user' SCIENCE_PWD='secret' ./initialize_docker_data.sh

## Build base images

### Build using Dev Release: 

```sh 
docker-compose -f docker-compose.build.yml build
```

### Build using Production Release: 
copy the env.template to .env

add this entry:
RELEASE=true

## Bring up the stack

### Environment file.

if you haven't done so already, copy env.template and update it to match your own settings.

#### Rabbit 
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

The importer config is defined in compose/netsage_shared.xml.  If you use different values then the defaults you may want to change them.

### Logstash 

Define the input rabbit Queue.  This should match the Importer output queue

```sh
rabbitmq_input_host=rabbit
rabbitmq_input_username=guest
rabbitmq_input_pw=guest

```

Define the output rabbit Queue.  This can be the docker container or any valid rabbit MQ server.

```sh
rabbitmq_output_host=rabbit
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
```

## Bring up the stack.

docker-compose up -d 