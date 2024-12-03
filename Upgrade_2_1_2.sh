#!/bin/bash

# Define file paths
compose_file="docker-compose.override.yml"
map_file="data/logstash-aggregation-maps"

# Function to check if a line has been deleted
check_deleted() {
  file=$1
  pattern=$2
  message=$3
  grep -q "$pattern" "$file"
  if [ $? -eq 0 ]; then
    echo "Error: $message"
    exit 1
  fi
}

# Function to check if a line has been modified/updated
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
sed -i "/logstash/d" "$compose_file"
sed -i "/netsage_pipeline/d" "$compose_file"
sed -i 's/2\.1\.[0-9]*/2.1.2/g' "$compose_file"

# Check if logstash: line was deleted
check_deleted "$compose_file" "logstash:" "Failed to delete the logstash entry."
check_deleted docker-compose.override.yml "netsage_pipeline" "Failed to delete the pipeline_logstash entry"

# Check other changes in docker-compose.override.yml
check_change "$compose_file" "netsage_importer:v2.1.2" "Failed to update pipeline_importer to netsage_importer:v2.1.2"
check_change "$compose_file" "netsage_collector:v2.1.2" "Failed to update netsage-nfdump-collector to netsage_collector:v2.1.2"

# Check and delete data/logstash-aggregation-maps if it exists
if [ -f "$map_file" ]; then
  rm "$map_file"
  
  # Verify if the deletion was successful
  if [ ! -f "$map_file" ]; then
    echo "File $map_file successfully deleted."
  else
    echo "Error: Failed to delete $map_file."
    exit 1
  fi
else
  echo "File $map_file does not exist. No action needed."
fi

echo "NetSage Ingest Pipeline successfully upgraded to 2.1.2"

