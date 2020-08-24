FROM alpine:3.12.3


ADD compose/data_volume/docker_init.sh /tmp/
ADD compose/data_volume/runner.sh /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer / && \
    apk update && \ 
    apk add bash wget nginx && \
    mkdir -p /run/nginx && \
    chmod a+x /tmp/*.sh

ENTRYPOINT ["/tmp/runner.sh", "bootstrap"]
