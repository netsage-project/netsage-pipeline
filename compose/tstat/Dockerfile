FROM centos:7

## Setup baseline 
RUN  \
    yum  -y update && \ 
    yum install -y epel-release wget  && \
    yum install -y libcap-devel.x86_64 && \
    yum groupinstall 'Development Tools' -y 

WORKDIR /tmp
RUN   yum install -y libpcap-devel.x86_64 libpcap.x86_64 && \
      wget http://tstat.polito.it/download/tstat-3.0.1.tar.gz  && \
     tar xvfz tstat-3.0.1.tar.gz && \
     cd tstat-3.0 && \
     ./autogen.sh && \
     ./configure && \
     make && make install 

VOLUME /tmp/data 

CMD ["tstat", "-u", "-l", "-i", "eth0", "-s", "/tmp/data/"]