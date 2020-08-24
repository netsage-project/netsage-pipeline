#!/usr/bin/env bash
set -e 
#echo "Initializing Meta data"
#/tmp/docker_init.sh init

status=1
while [[ $status -ne "0" ]]; do
        nc -vz data_volume 80 >& /dev/null  || echo "Port not open"
        status=$?
        echo "waiting for port, sleeping for 10 seconds"
        sleep 10
done

echo "Data expected to Initialized by Data Volume"
echo "Starting LogStash"
/usr/local/bin/docker-entrypoint
