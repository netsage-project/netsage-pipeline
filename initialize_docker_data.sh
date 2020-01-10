#!/usr/bin/env bash

mkdir -p data/cache/ && echo "Cache directory created" || echo "cache dir already exists"

L_USER=${SCIENCE_USER:-<username>}
L_PASSWD=${SCIENCE_PWD:-<pw>}

wget --user $L_USER --password $L_PASSWD https://scienceregistry.grnoc.iu.edu/exported/GeoLite2-ASN.mmdb --no-use-server-timestamps -q -O data/cache/GeoLite2-ASN.mmdb
wget --user $L_USER --password $L_PASSWD  https://scienceregistry.grnoc.iu.edu/exported/scireg.mmdb --no-use-server-timestamps -q -O data/cache/scireg.mmdb
wget --user $L_USER --password $L_PASSWD  https://scienceregistry.grnoc.iu.edu/exported/GeoLite2-City.mmdb --no-use-server-timestamps -q -O data/cache/GeoLite2-City.mmdb
