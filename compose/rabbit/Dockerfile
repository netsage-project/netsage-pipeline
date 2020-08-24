FROM rabbitmq:3.8.11-management

RUN apt-get update && apt-get install -y netcat

COPY compose/rabbit/rabbit_run.sh  /tmp

CMD [ "/tmp/rabbit_run.sh" ]