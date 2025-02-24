#!/usr/bin/env python3

# simple program to look up ASN from Org Name 
#Looks up their ASN using CAIDA, PeeringDB, and RIPE Stat.
# note: only CAIDA method still works, but other code here for reference
#
# if ASN not found, the org is likely using addresses from the regional network's ASN
#  In this case, set to DEFAULT_ASN (set below)

# input file is a csv file
#  set the delimiter in the code below, and set the row[] to the correct column
#  eg:             org_name = row[1].strip()


import subprocess
import requests
import csv
import re
import argparse
import sys
import urllib.parse

CAIDA_API_URL = "https://api.asrank.caida.org/v2/restful/asns"
# ASN to use if lookup fails
#DEFAULT_ASN = 21976  # NJEdge
DEFAULT_ASN = 600  # OARnet

def extract_number(string):
    match = re.search(r'\d+', string)
    return int(match.group()) if match else 0

# Function to fetch ASN using CAIDA AS Rank API
def lookup_asn_CAIDA(org_name):

    encoded_name = urllib.parse.quote_plus(org_name)  # Handle spaces
    url = f"{CAIDA_API_URL}/orgs?name={encoded_name}"
    try:
        response = requests.get(CAIDA_API_URL, params={"name": org_name}, timeout=10)
        print(f"   CAIDA Request URL: {response.url}")
        #print ("CAIDA returned: ", response)

        if response.status_code != 200:
            print(f"[CAIDA] API request failed for {org_name} (Status Code: {response.status_code})")
            return None

        data = response.json()
        #print(f"[DEBUG] API response for {org_name}: {data}")

        if "data" in data and "asns" in data["data"] and "edges" in data["data"]["asns"]:
            asn_list = data["data"]["asns"]["edges"]
            if asn_list:
                asn = asn_list[0]["node"]["asn"]
                print(f"   [SUCCESS] ASN found: {asn} for {org_name}")
                return asn

    except Exception as e:
        print(f"❌ CAIDA API error: {e}")
        return None


def lookup_asn_peeringdb(org_name):
    """Query PeeringDB API for ASNs by organization name."""

# note: can only do 1 query per hour without API key!!

    encoded_name = urllib.parse.quote_plus(org_name)  # Handle spaces
    url = f"https://peeringdb.com/api/org?name__icontains={encoded_name}"
    print ("peeringdb request: ", url)
    try:
        response = requests.get(url, timeout=5)
        print ("peeringdb returned: ", response)
        if response.status_code == 200:
            data = response.json()
            asns = set()
            for org in data.get("data", []):
                for net in org.get("net_set", []):
                    asn = net.get("asn")
                    print ("peeringdb asn: ", asn)
                    if asn:
                        asns.add(f"AS{asn}")
            return asns if asns else None
    except Exception:
        print ("peeringdb error \n")
        return None

def lookup_asn_ripe(org_name):
    """Query RIPE Stat API for ASNs by organization name."""

# note: not working??

    encoded_name = urllib.parse.quote_plus(org_name)  # Handle spaces
    url = "https://stat.ripe.net/data/as-organizations/data.json"
    params = {"org_name": encoded_name} 
    
    try:
        response = requests.get(url, params=params)
        print(f"RIPE Request URL: {response.url}")
        print ("RIPE returned: ", response)
        if response.status_code == 200:
            data = response.json()
            results = data.get("data", {}).get("results", [])
            asns = [entry["key"] for entry in results if entry.get("resource_type") == "asn"]
            print ("RIPE asn: ", asns)
            return asns if asns else None
    except Exception:
        print ("RIPE error \n")
        return None

def lookup_asn(org_name):
    """Try all methods in order: CAIDA → PeeringDB → RIPE Stat"""
    asns = lookup_asn_CAIDA(org_name)
    if asns:
        return asns  # Found via whois

    # not useful without an API key
    #asns = lookup_asn_peeringdb(org_name)
    #if asns:
    #    return asns  # Found via PeeringDB

    # no longer supported by RIPE..
    #asns = lookup_asn_ripe(org_name)
    #if asns:
    #    return asns  # Found via RIPE Stat

    return None  # No ASNs found

def process_csv(input_file, output_file):
    """Read organizations from input CSV and write ASN results to output CSV."""
    with open(input_file, mode='r', newline='', encoding='utf-8') as infile, \
         open(output_file, mode='w', newline='', encoding='utf-8') as outfile:
        
        #reader = csv.reader(infile)
        # to change delimiter (if org names have commas)
        reader = csv.reader(infile, delimiter=',')

        header = next(reader)  # Read the header row
        #writer = csv.writer(outfile)
        writer = csv.writer(outfile, quotechar='"', quoting=csv.QUOTE_ALL)


        # Write header
        writer.writerow(["org_name", "ASN"])

        for row in reader:
            if not row:  # Skip empty rows
                continue

            org_name = row[1].strip()
            if not org_name:
                continue
            asn = row[1]
            as_number = extract_number(asn)

            if as_number > 0:
               print (f"input file contains ASN {asn}, no lookup needed")
            else:
               print(f"🔍 Looking up: {org_name}")
               asn = lookup_asn(org_name)
               if not asn:
                   print ("   No ASNs found.")
                   #sys.exit()

            if asn:
                writer.writerow([org_name, asn])
                print(f"✅ Found ASNs for {org_name}: {asn}")
            else:
                # skip if no ASN for now...
                writer.writerow([org_name, DEFAULT_ASN])
                print(f"❌ No ASNs found for {org_name}")

def main():
    parser = argparse.ArgumentParser(description="Lookup ASN for a list of organizations from a CSV file.")
    parser.add_argument("-i", "--input", required=True, help="Input CSV file containing organization names.")
    parser.add_argument("-o", "--output", required=True, help="Output CSV file to save results.")

    args = parser.parse_args()
    process_csv(args.input, args.output)

if __name__ == "__main__":
    main()


