#!/usr/bin/env bash

mkdir -p /data/cache/ && echo "Cache directory created" || echo "cache dir already exists"

FILES="GeoLite2-ASN scireg GeoLite2-City"

## Download all files to temporary destination
for f in $FILES 
do
    wget  https://scienceregistry.grnoc.iu.edu/exported/$f.mmdb --no-use-server-timestamps -q -O /data/cache/$f.tmp
done

## Rename the temporary files to replace the production ones.
for f in $FILES 
do
    mv /data/cache/$f.tmp /data/cache/$f.mmdb
done
