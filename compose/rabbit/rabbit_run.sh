#!/usr/bin/env bash
set -em

##
function main() {
    /usr/local/bin/docker-entrypoint.sh rabbitmq-server &

    until nc -z -v -w30 localhost 15672; do
        echo "Waiting 5 second until rabbit is coming up..."
        sleep 5
    done

    ## Ensure the queues are created on start
    ## Sflow Queues
    echo "Creating Queue for Sflow named: ${rabbitmq_input_sflow_key}"
    rabbitmqadmin declare queue name=${rabbitmq_input_sflow_key} durable=true
    rabbitmqadmin declare binding source=amq.direct destination=${rabbitmq_input_sflow_key} routing_key=${rabbitmq_input_sflow_key}
    ## Netflow Queues
    echo "Creating Queue for Netflow named: ${rabbitmq_input_netflow_key}"
    rabbitmqadmin declare queue name=${rabbitmq_input_netflow_key} durable=true
    rabbitmqadmin declare binding source=amq.direct destination=${rabbitmq_input_netflow_key} routing_key=${rabbitmq_input_netflow_key}

    echo "Creating Queue for Output named: ${rabbitmq_output_key}"
    rabbitmqadmin declare queue name=${rabbitmq_output_key} durable=true
    rabbitmqadmin declare binding source=amq.direct destination=${rabbitmq_output_key} routing_key=${rabbitmq_output_key}

    fg %1

}

main
