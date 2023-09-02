# Note: centos is no longer supported!
# But GRNOC perl stuff seems to only work in Centos 7...
# tried both rockylinux and almalinux, (and even CentOS 8) but no luck
#
FROM centos:7

## Stage 1 Build the PRMs
## Setup baseline 
#
### needed to fix Centos 8 mirror issue
#RUN cd /etc/yum.repos.d/
#RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN  \
    yum  -y update && \
    yum install -y epel-release && \
    yum install -y rpm-build perl-ExtUtils-MakeMaker make
 

COPY . /root/code
WORKDIR /root/code

RUN mkdir rpmbuild && cd rpmbuild && \
    mkdir BUILD BUILDROOT RPMS SOURCES SPECS SRPMS TMP && \
    cd /root/code/ && perl Makefile.PL 


RUN make rpm 

## Stage 2
FROM centos:7

COPY --from=0 /root/rpmbuild/RPMS/noarch/*.rpm /tmp

COPY compose/importer/grnoc7.repo /etc/yum.repos.d/grnoc7.repo 
COPY compose/importer/docker_init.sh  /tmp/ 
COPY compose/importer/run.sh  /tmp/ 
COPY compose/importer/netsage_shared.xml /etc/grnoc/netsage/deidentifier/  
COPY compose/importer/logging.conf /etc/grnoc/netsage/deidentifier/  

## Setup baseline 

RUN  \
    yum  -y update && \
    yum install -y  dnf epel-release  && \
    yum install -y nfdump wget && \
    dnf install -y /tmp/*.rpm  && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN mkdir /data; chown 777 /data

## Exposed but likely not needed
VOLUME /var/cache/netsage/
VOLUME /etc/grnoc/netsage/deidentifier/ 
VOLUME /var/lib/grnoc/netsage/

#Data volume 
VOLUME /data
## Config exposed
VOLUME /etc/grnoc/netsage/

CMD /tmp/run.sh
