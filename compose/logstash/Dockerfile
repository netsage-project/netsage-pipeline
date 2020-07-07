FROM docker.elastic.co/logstash/logstash:7.8.0

#Create symlink so can use paths from production with logstash docker defaults
USER root


RUN yum makecache && \
    yum install -y wget  &&  \
    mkdir -p /etc/logstash && \
    ln -s /usr/share/logstash/pipeline /etc/logstash/conf.d && \
    logstash-plugin  install logstash-codec-sflow  logstash-codec-netflow && \
    mkdir -p /data/cache/ && chown logstash:logstash -R /data/cache/

COPY --chown=logstash:logstash compose/logstash/docker_init.sh  /tmp/ 
COPY --chown=logstash:logstash compose/logstash/runner.sh  /tmp/ 
COPY --chown=logstash:root compose/logstash/pipelines.yml  /usr/share/logstash/config/

USER logstash

VOLUME /data
VOLUME  /var/cache/netsage

ENTRYPOINT ["/tmp/runner.sh"]
