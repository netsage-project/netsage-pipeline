FROM centos:7

## Stage 1 Build the PRMs
## Setup baseline 
RUN  \
    yum  -y update && \ 
    yum install -y epel-release && \
    yum install -y rpm-build perl-ExtUtils-MakeMaker make

COPY . /root/code
WORKDIR /root/code

RUN mkdir rpmbuild && cd rpmbuild && \
    mkdir BUILD BUILDROOT RPMS SOURCES SPECS SRPMS TMP && \
    cd /root/code/ && perl Makefile.PL 


#RUN chown -R coder /home/coder 
RUN make rpm 

## Stage 2
FROM centos:7

COPY --from=0 /root/rpmbuild/RPMS/noarch/*.rpm /tmp

COPY compose/grnoc7.repo /etc/yum.repos.d/grnoc7.repo 
COPY compose/logstash.repo /etc/yum.repos.d/logstash.repo 
COPY compose/pipeline/docker_init.sh  /tmp/ 
COPY compose/pipeline/run.sh  /tmp/ 
COPY compose/netsage_shared.xml /etc/grnoc/netsage/deidentifier/  
COPY compose/logging.conf /etc/grnoc/netsage/deidentifier/  

## Setup baseline 
RUN  \
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch  && \
    yum  -y update && \ 
    yum install -y  dnf epel-release  && \
    yum install -y python-pip nfdump wget && \
    dnf install -y /tmp/*.rpm  && \
    pip install --upgrade pip pika && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN mkdir /data; chown 777 /data

## Exposed but likely not needed
VOLUME /var/cache/netsage/

#Data volume 
VOLUME /data
## Config exposed
VOLUME /etc/grnoc/netsage/

CMD /tmp/run.sh