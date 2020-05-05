#!/usr/bin/env bash

/tmp/docker_init.sh

netsage-netflow-importer-daemon --nofork  --config /etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml 