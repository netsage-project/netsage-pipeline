#!/bin/sh
#
# script to download mmdb files and CAIDA csv file from central repo
#
# NOTE: a similar script is currently used by the importer docker image
# The importer should be updated to remove that script

DATA_DIR="./data/cache"
#DATA_DIR="/tmp/data/cache"  # for testing

# If a command line argument is provided, override the default DATA_DIR
if [ -n "$1" ]; then
    DATA_DIR="$1"
fi

REPO="https://epoc-rabbitmq.tacc.utexas.edu/NetSage"
GITREPO="https://netsage-project.github.io/Science-Registry/"
CAIDA_FILE="CAIDA-org-lookup.csv"

MAXMIND_MMDB_FILES="GeoLite2-City.mmdb GeoLite2-ASN.mmdb"
SCIREG_MMDB_FILES="communities.mmdb scireg.mmdb"

# Ensure cache directory exists; only echo if it does not exist
if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR" && echo "Cache directory ${DATA_DIR} created"
fi

echo "Downloading mmdb files from $REPO..."
for FILE in $MAXMIND_MMDB_FILES; do
    echo "Downloading file $FILE"
    # note: if this script is run in Alpine Linux docker container, then the version of
    #  wget does not support the -N flag, and will need to download the file every time
    if ! wget -N -q -P "$DATA_DIR" "$REPO/$FILE"; then   # use this for gnu wget
    #if ! wget -q -O "$DATA_DIR/$FILE" "$REPO/$FILE"; then # use this for BusyBox wget (alpine linux)
        echo "Failed to download $FILE" >&2
    fi
done

echo "Downloading mmdb files from $GITREPO..."
for FILE in $SCIREG_MMDB_FILES; do
    echo "Downloading file $FILE"
    if ! wget -N -q -P "$DATA_DIR" "$GITREPO/$FILE"; then 
        echo "Failed to download $FILE" >&2
    fi
done

echo "Downloading CAIDA csv file $CAIDA_FILE from $REPO"
#if ! wget -N -q -P "$DATA_DIR" "$REPO/$CAIDA_FILE"; then
if ! wget -q -O "$DATA_DIR/$CAIDA_FILE" "$REPO/$CAIDA_FILE"; then
    echo "Failed to download $CAIDA_FILE" >&2
    exit 1
fi


