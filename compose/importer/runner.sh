#!/usr/bin/env bash


echo "Data expected to be initialized by data volume"

status=1
while [[ $status -ne "0" ]]; do
        nc -vz data_volume 80 >& /dev/null  || echo "Port not open"
        status=$?
        echo "waiting for port, sleeping for 10 seconds"
        sleep 10
done

netsage-netflow-importer-daemon --nofork --config /etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
