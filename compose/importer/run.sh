#!/usr/bin/env bash

/tmp/docker_init.sh

/tmp/netsage-netflow-importer-daemon.pl --nofork  --config /tmp/conf/netsage_netflow_importer.xml --sharedconfig /tmp/conf/netsage_shared.xml
