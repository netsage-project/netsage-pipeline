FROM centos:7

COPY grnoc7.repo /etc/yum.repos.d/grnoc7.repo
COPY logstash.repo /etc/yum.repos.d/logstash.repo

## Setup baseline 
RUN  \
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch  && \
    yum  -y update && \ 
    yum install -y rpm-build  epel-release  && \
    yum install -y python-pip nfdump cronie

## Uncomment this line to use release version instead
COPY --from=netsage/pipeline/nfdump:builder /root/rpmbuild/RPMS/noarch/*.rpm /tmp
COPY ./pipeline/build.sh  /tmp/

##Build.sh chooses to install the RELEASE vs the DEVEL.  Defaults to DEV version
RUN bash ./tmp/build.sh 


## Skip broken disregards logstash since it won't be used
RUN for i in $(ls /tmp/*.rpm); do yum localinstall -y $i; done;

RUN yum install -y vim  && pip install --upgrade pip pika

COPY netsage_shared.xml /etc/grnoc/netsage/deidentifier/ 
COPY logging.conf /etc/grnoc/netsage/deidentifier/ 

RUN mkdir /data; chown 777 /data

## Exposed but likely not needed
VOLUME /var/cache/netsage/

#Data volume 
VOLUME /data
## Config exposed
VOLUME /etc/grnoc/netsage/

CMD netsage-netflow-importer-daemon --nofork  --config /etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml 
