#!/bin/bash
echo "Checking all community files in this directory"

for f in community-*.json; do
    [ -e "$f" ] || continue
    asn_count=$(jq '[.[].asn] | unique | length' "$f")
    if [ "$asn_count" -gt 1 ]; then
        out="${f%.json}.json.updated"
        echo "Checking file $f"
        check_community.py --input "$f" --output "$out" > check_community.log 2>&1
    else
        echo "Skipping $f (only $asn_count ASN)"
    fi
done 

echo "Done. Output logged to check_community.log"

