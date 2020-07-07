#!/usr/bin/env bash

FILES="GeoLite2-ASN scireg GeoLite2-City"

function update() {
    mkdir -p /data/cache/ && echo "Cache directory created" || echo "cache dir already exists"

    ## Download all files to temporary destination
    for f in $FILES; do
        wget --continue https://scienceregistry.grnoc.iu.edu/exported/$f.mmdb --no-use-server-timestamps -q -O /data/cache/$f.tmp
    done

    ## Rename the temporary files to replace the production ones.
    for f in $FILES; do
        mv /data/cache/$f.tmp /data/cache/$f.mmdb
    done
}

function first_run() {
    force_update=false
    for f in $FILES; do
        if test ! -f "/data/cache/$f.mmdb"; then
            force_update=true
            break
        fi
    done

    if $force_update -eq "true"; then
        update
    else
        echo "All files already present, skipping Science Registry download"
    fi

}

if [ "$#" -gt 0 ]; then
    ## Will check if files exist before downloading
    first_run
else
    # Triggered by crontab to update the files periodically.
    update
fi
