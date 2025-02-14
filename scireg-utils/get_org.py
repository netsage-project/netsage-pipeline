#!/usr/bin/env python3

# looks up ORG Name from CAIDA file
# use this to look for bad ASNs in community files

import argparse
import json
import csv

CAIDA_DATA = "./CAIDA-org-lookup.csv"

def load_as_to_org_mapping(as_org_file):
    """Load the AS-to-ORG mapping from the CAIDA file."""
    print ("Loading file: ", as_org_file)
    as_to_org = {}
    with open(as_org_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter=',')
        for row in reader:
            if len(row) < 2:
                continue
            asn, org_name = row[0], row[1]
            as_to_org[asn] = org_name

    # Debugging: Print first few entries
    #print("First few entries in as_to_org:")
    #for i, (asn, org) in enumerate(as_to_org.items()):
    #    if i >= 5:
    #        break
    #    print(f"ASN: {asn}, Org: {org}")
    
    return as_to_org

def lookup_org(input_json, as_org_file):
    #Reads ASN numbers from a community.json file, looks up org names

    as_to_org = load_as_to_org_mapping(as_org_file)
    
    with open(input_json, 'r', encoding='utf-8') as infile:
        data = json.load(infile)
    
    for entry in data:
        asn = entry.get('asn')
        if asn and asn in as_to_org:
            entry['Org_Name'] = as_to_org[asn]
        else:
            entry['Org_Name'] = 'Unknown'
        print (f"ASN: {asn} is for Organization: {entry['Org_Name']}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Lookup Org Names for ASN numbers from a JSON file.")
    parser.add_argument("input_file", help="Path to the input JSON file containing ASN numbers.")
    
    args = parser.parse_args()
    lookup_org(args.input_file, CAIDA_DATA)


