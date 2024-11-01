#!/bin/bash

# Check if the expected changes were made
check_change() {
  file=$1
  pattern=$2
  message=$3
  grep -q "$pattern" "$file"
  if [ $? -ne 0 ]; then
    echo "Error: $message"
    exit 1
  fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root."
  exit 1
fi

# Update docker-compose.override.yml
sed -i -e "pipeline_logstash:v2.1.0|d" docker-compose.override.yml
sed -i -e "s|pipeline_importer:v2.1.1|netsage_importer:v2.1.2|" docker-compose.override.yml
sed -i -e "s|netsage_collector:v2.1.0|netsage_collector:v2.1.2|" docker-compose.override.yml

# Check changes in docker-compose.override.yml
check_change docker-compose.override.yml "netsage_pipeline:v2.1.2" "Failed to update pipeline_logstash to netsage_pipeline:v2.1.2"
check_change docker-compose.override.yml "netsage_importer:v2.1.2" "Failed to update pipeline_importer to netsage_importer:v2.1.2"
check_change docker-compose.override.yml "netsage_collector:v2.1.2" "Failed to update netsage-nfdump-collector to netsage_collector:v2.1.2"

echo "NetSage Ingest Pipeline successfully upgraded to 2.1.2"

