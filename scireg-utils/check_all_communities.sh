#!/bin/bash
echo "Checking all community files in this directory"

for f in community-*.json; do
    [ -e "$f" ] || continue
    case "$f" in
        *ACCESS*) echo "Skipping $f (ACCESS file), as not all subnets in those ASNs are ACCESS"; continue ;;
    esac
    total=$(jq '[.[].asn] | length' "$f")
    unique=$(jq '[.[].asn] | unique | length' "$f")
    if [ "$total" -eq "$unique" ]; then
        out="${f%.json}.json.updated"
        echo "Checking file $f"
        check_community.py --input "$f" --output "$out" > check_community.log 2>&1
    else
        echo "Skipping $f (duplicate ASNs present)"
    fi
done 

echo "Done. Output logged to check_community.log"

