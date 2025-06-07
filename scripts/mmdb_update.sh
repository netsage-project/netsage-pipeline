#!/bin/sh
#
# script to download mmdb files and CAIDA csv file from central repo
#
# NOTE: a similar script is currently used by the importer docker image
# The importer should be updated to remove that script

#set -x

DATA_DIR="./data/cache"
#DATA_DIR="/tmp/data/cache"  # for testing

# If a command line argument is provided, override the default DATA_DIR
if [ -n "$1" ]; then
    DATA_DIR="$1"
fi

REPO="https://downloads.netsage.io"
CAIDA_FILE="CAIDA-org-lookup.csv"

# List of known MMDB files (as a whitespace separated string)
MMDB_FILES="GeoLite2-City.mmdb GeoLite2-ASN.mmdb communities.mmdb scireg.mmdb"

# Ensure cache directory exists; only echo if it does not exist
if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR" && echo "Cache directory ${DATA_DIR} created"
fi

echo "Downloading mmdb files..."
for FILE in $MMDB_FILES; do
    echo "Downloading file $FILE"
    TMPFILE=$(mktemp)

    if wget -q -O "$TMPFILE" "$REPO/$FILE"; then
        mv "$TMPFILE" "$DATA_DIR/$FILE"
    else
        echo "Failed to download $FILE" >&2
        rm -f "$TMPFILE"
    fi
done

echo "Downloading CAIDA file $CAIDA_FILE"
TMPFILE=$(mktemp)

if wget -q -O "$TMPFILE" "$REPO/$CAIDA_FILE"; then
    mv "$TMPFILE" "$DATA_DIR/$CAIDA_FILE"
else
    echo "Failed to download $CAIDA_FILE" >&2
    rm -f "$TMPFILE"
    exit 1
fi

chmod +r $DATA_DIR/*
echo "Done downloading files to $DATA_DIR"

