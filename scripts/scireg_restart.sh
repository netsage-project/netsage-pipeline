#!/bin/sh

WATCH_DIR="/data/cache"
# for testing
#WATCH_DIR="../data/cache"

CONTAINER_NAME="NetSage_Logstash"
CHECK_INTERVAL=900 # seconds

# Calculate the total size of files in the directory
calculate_size() {
  find "$WATCH_DIR" -type f -exec stat -c%s {} \; | awk '{sum+=$1} END {print sum}'
}

# Get the initial size of the directory
initial_size=$(calculate_size)

while true; do
  #check if any new files ready to download, and update if necessary
  echo "Calling scripts/mmdb_update.sh $WATCH_DIR"
  scripts/mmdb_update.sh $WATCH_DIR

  current_size=$(calculate_size)

  if [ "$current_size" != "$initial_size" ]; then
    echo "Science Registry or CAIDA cache updated. Restarting $CONTAINER_NAME..."
    docker restart $CONTAINER_NAME
    initial_size=$current_size
  fi

  sleep $CHECK_INTERVAL
done

