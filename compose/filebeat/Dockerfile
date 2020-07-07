FROM docker.elastic.co/beats/filebeat:7.8.0
#Create symlink so can use paths from production with logstash docker defaults
USER root

COPY compose/filebeat/filebeat.yml  /usr/share/filebeat
RUN filebeat modules enable netflow
COPY compose/filebeat/netflow_module.yml  /usr/share/filebeat/modules.d/netflow.yml