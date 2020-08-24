FROM docker.elastic.co/logstash/logstash:7.10.1

#Create symlink so can use paths from production with logstash docker defaults
USER root


RUN  \
    mkdir -p /etc/logstash && \
    ln -s /usr/share/logstash/pipeline /etc/logstash/conf.d && \
    yum update -y && \
    yum install -y wget nc &&  \
    mkdir -p /data/cache && \
    chown logstash:root -R /data

COPY --chown=logstash:root compose/logstash/pipelines.yml  /usr/share/logstash/config/
COPY --chown=logstash:root compose/logstash/docker_init.sh  /tmp/
COPY --chown=logstash:root compose/logstash/runner.sh  /tmp/

# USER logstash
USER root

VOLUME /data
VOLUME /var/cache/netsage
VOLUME /var/cache/netsage
VOLUME /var/lib/grnoc/netsage/
VOLUME /usr/share/logstash/config/


ENTRYPOINT ["/tmp/runner.sh"]
