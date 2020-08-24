#!/usr/bin/env bash
set -e
echo "Initializing Meta data"
/tmp/docker_init.sh init
echo "Starting S6 Init"
/init
