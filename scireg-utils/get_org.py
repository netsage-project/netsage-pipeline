#!/usr/bin/env python3

# looks up ORG Name from CAIDA file
# use this to look for bad ASNs in community files

import argparse
import json
import csv

CAIDA_DATA = "./CAIDA-org-lookup.csv"


def load_as_to_org_mapping(as_org_file):
    """Load the AS-to-ORG mapping from the CAIDA file."""
    print("Loading file:", as_org_file)
    as_to_org = {}
    with open(as_org_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter=',')
        for row in reader:
            if len(row) < 2:
                continue
            asn, org_name = row[0], row[1]
            as_to_org[asn] = org_name
    
    return as_to_org

def lookup_org(input_json, as_org_file, output_json=None):
    """Reads ASN numbers from a JSON file, looks up org names, and optionally writes output to a file."""
    as_to_org = load_as_to_org_mapping(as_org_file)
    
    with open(input_json, 'r', encoding='utf-8') as infile:
        data = json.load(infile)
    
    for entry in data:
        asn = entry.get('asn')
        if asn and asn in as_to_org:
            entry['Org_Name'] = as_to_org[asn]
        else:
            entry['Org_Name'] = 'Unknown'
        print(f"ASN: {asn} is for Organization: {entry['Org_Name']}")
    
    if output_json:
        with open(output_json, 'w', encoding='utf-8') as outfile:
            json.dump(data, outfile, indent=4)
        print(f"Output written to {output_json}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Lookup Org Names for ASN numbers from a JSON file.")
    parser.add_argument("-i", "--input", help="Path to the input JSON file containing ASN numbers.", required=True)
    parser.add_argument("-o", "--output", help="Path to the output JSON file to store the results.", default=None)
    
    args = parser.parse_args()
    lookup_org(args.input, CAIDA_DATA, args.output)


