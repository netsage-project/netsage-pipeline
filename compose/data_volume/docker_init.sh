#!/usr/bin/env bash
set -e

#DATA_DIR=/var/lib/grnoc/netsage/
DATA_DIR=/data/cache/
INPUT_DATA=/data/input_data/
LOGSTASH_DIR=/usr/share/logstash/pipeline/support

mkdir -p $DATA_DIR && echo "Cache directory ${DATA_DIR} created" || echo "cache dir ${DATA_DIR} already exists"
mkdir -p $INPUT_DATA && echo "Importer input directory ${INPUT_DATA} created" || echo "importer input dir ${INPUT_DATA} already exists"

FILES="GeoLite2-ASN scireg GeoLite2-City"
CAIDA_FILES="CAIDA-org-lookup"
RUBY_DATA="FRGP-members-list ilight-members-list"

function downloadFiles() {
    ext=$1
    shift 1
    ## Download all files to temporary destination
    for f in $@; do
        wget https://scienceregistry.grnoc.iu.edu/exported/${f}.${ext} --no-use-server-timestamps -q -O ${DATA_DIR}/$f.tmp
    done

    ## Rename the temporary files to replace the production ones.
    for f in $@; do
        mv ${DATA_DIR}/$f.tmp ${DATA_DIR}/${f}.${ext}
    done

}

echo "Download ScienceRegistry and maxmind"
downloadFiles mmdb $FILES
echo "Download Caida Files"
downloadFiles csv $CAIDA_FILES
echo "Download Ruby files"
DATA_DIR=$LOGSTASH_DIR
downloadFiles rb $RUBY_DATA

## Used to track when bootstrap initialization is completed
if [[ $# -ne "0" ]]; then
    echo "Starting nginx for health checks"
    nginx
else
    echo "Skipping opening monitoring port"
fi
