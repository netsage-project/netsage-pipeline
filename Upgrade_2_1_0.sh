#!/bin/bash

# Function to check if the expected changes were made
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

# Function to check if the directory is removed
check_removal() {
  directory=$1
  if [ -d "$directory" ]; then
    echo "Error: Failed to remove $directory"
    exit 1
  fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root."
  exit 1
fi

# Update docker-compose.override.yml
sed -i -e "s|pipeline_logstash:v2.0.0|netsage_pipeline:v2.1.0|" docker-compose.override.yml
sed -i -e "s|pipeline_importer:v2.0.0|netsage_importer:v2.1.0|" docker-compose.override.yml
sed -i -e "s|netsage-nfdump-collector:alpine-1.6.23|netsage_collector:v2.1.0|" docker-compose.override.yml
sed -i -e "s|nfdump-collector:alpine-1.6.23|netsage_collector:v2.1.0|" docker-compose.override.yml
sed -i -e "s|nfcapd -T all -l /data -S 1 -w -z -p|nfcapd -w /data -S 1 -z -p|" docker-compose.override.yml
sed -i -e "s|sfcapd -T all -l /data -S 1 -w -z -p|sfcapd -w /data -S 1 -z -p|" docker-compose.override.yml

# Check changes in docker-compose.override.yml
check_change docker-compose.override.yml "netsage_pipeline:v2.1.0" "Failed to update pipeline_logstash to netsage_pipeline:v2.1.0"
check_change docker-compose.override.yml "netsage_importer:v2.1.0" "Failed to update pipeline_importer to netsage_importer:v2.1.0"
check_change docker-compose.override.yml "netsage_collector:v2.1.0" "Failed to update netsage-nfdump-collector to netsage_collector:v2.1.0"
check_change docker-compose.override.yml "netsage_collector:v2.1.0" "Failed to update nfdump-collector to netsage_collector:v2.1.0"
check_change docker-compose.override.yml "nfcapd -w /data -S 1 -z -p" "Failed to update nfcapd command"
check_change docker-compose.override.yml "sfcapd -w /data -S 1 -z -p" "Failed to update sfcapd command"

# Remove the directory
rm -rf ./data/rabbit

# Verify the directory has been deleted
check_removal ./data/rabbit

echo "Pipeline successfully upgraded to 2.1.0"

