# new version of importer container
# to build:
# cd netsage-pipeline
# docker build -f compose/importer.new/Dockerfile -t netsage-importer:latest .

FROM ubuntu:latest

WORKDIR /root/code

RUN apt-get update
RUN apt-get install -y vim bash perl nfdump librabbitmq-dev wget netcat-traditional iputils-ping
# install all required perl modules
RUN apt-get install -y libnet-amqp-perl libxml-libxml-perl libmoo-perl libxml-simple-perl libxml-xpath-perl libjson-xs-perl libmath-round-perl liblist-moreutils-perl libdatetime-perl libpath-class-perl libdata-validate-ip-perl libnet-ip-perl libhash-merge-perl libtype-tiny-perl libparallel-forkmanager-perl libproc-daemon-perl liblog-log4perl-perl
#if need to build cpan modules, etc, add this:
RUN apt-get install -y cpanminus build-essential make libssl-dev

# the apt package for AMQP not working for some reason, but this works (needs --force):
RUN cpanm --force Net::AMQP::RabbitMQ 

# copy over necessary files
COPY compose/importer /tmp/
COPY compose/importer/docker_init.sh  /tmp/
COPY compose/importer/run.sh  /tmp/
COPY compose/importer/conf /tmp/conf/

RUN mkdir /data; chown 777 /data

## still Needed??
VOLUME /var/cache/netsage/
#Data volume
VOLUME /data/
## Config exposed
VOLUME /etc/netsage/
ENV PERL5LIB=/tmp/

#start perl importer script
CMD /tmp/run.sh

