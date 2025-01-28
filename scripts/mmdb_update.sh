#!/usr/bin/env bash
# script to download mmdb files and CAIDA csv file from central repo
#
# NOTE: the exact same script is used by the importer docker image
# Keep this file and the verion in docker-images/importer the same

DATA_DIR="/data/cache"
#DATA_DIR="/tmp/data/cache"  # for testing

REPO="https://epoc-rabbitmq.tacc.utexas.edu/NetSage"
CAIDA_FILE="CAIDA-org-lookup.csv"

# List of known MMDB files
# include testing files for now
MMDB_FILES=("GeoLite2-City.mmdb" "GeoLite2-ASN.mmdb" "communities.mmdb" "newScireg.mmdb" "newScireg-testing.mmdb" "scireg.mmdb") 
#MMDB_FILES=("GeoLite2-City.mmdb" "GeoLite2-ASN.mmdb" "communities.mmdb" "scireg.mmdb") 

# Ensure cache directory exists
if mkdir -p "$DATA_DIR"; then
    echo "Cache directory ${DATA_DIR} created"
else
    echo "Cache directory ${DATA_DIR} already exists"
fi

echo "Downloading mmdb files..."
for FILE in "${MMDB_FILES[@]}"; do
    echo "Getting file "${FILE}
    wget -N -q -P "${DATA_DIR}" "${REPO}/${FILE}" || {
            echo "Failed to download ${FILE}" >&2
    }
done

echo "Downloading CAIDA file ${CAIDA_FILE}"
wget "${REPO}/${CAIDA_FILE}" -N -q -P "${DATA_DIR}" || {
    echo "Failed to download ${CAIDA_FILE}" >&2
    exit 1
}
echo "Done."

