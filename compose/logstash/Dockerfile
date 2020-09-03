FROM logstash:7.4.2

#Create symlink so can use paths from production with logstash docker defaults
USER root
RUN mkdir -p /etc/logstash && \
    ln -s /usr/share/logstash/pipeline /etc/logstash/conf.d

COPY --chown=logstash:root compose/logstash/pipelines.yml  /usr/share/logstash/config/

USER logstash

VOLUME /var/cache/netsage
VOLUME /var/lib/grnoc/netsage/