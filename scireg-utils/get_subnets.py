#!/usr/bin/env python3

# note: requires:
#    pip install requests beautifulsoup4

# simple script to scrape ipv4 and ipv6 subnet info from bgp.he.net based on the ASN

# note: currently filenames and community name is hardcoded below
# adjust these as needed in the code below
#    org_name = row[1]  # Organization name
#    asn = row[0]        # ASN
#
# also might need to adjust the fuzzy_match threshold

# Note: for reasons I dont understand, the queary for url 'https://bgp.he.net/AS103#_prefixes' returns
# both V4 and V6 subnets, unlike what happens in a browser. WTF?

import csv
import requests
import json
import time
import re
import sys
from bs4 import BeautifulSoup
from difflib import SequenceMatcher

# File Paths
INPUT_CSV = "organizations_with_asn.csv"
OUTPUT_JSON = "subnets.json"
BASE_URL = "https://bgp.he.net/"
COMMUNITY = "OARnet"  # Set static community value

################################################################

def extract_numbers(s):
    match = re.search(r'\d+', s)  # Find the first sequence of digits
    return match.group() if match else ""

def fuzzy_match(org1, org2, threshold=0.9):
    """Return True if org1 and org2 match with a similarity above the threshold."""
    ratio = SequenceMatcher(None, org1.lower(), org2.lower()).ratio()
    return ratio >= threshold

def get_subnets(asn, expected_org_name, version=4):
    if version == 4:
        url = f"{BASE_URL}AS{asn}#_prefixes"
    else:
        url = f"{BASE_URL}AS{asn}#_prefixes{version}"
    print(f"[INFO] Fetching subnets for ASN {asn} from {url}")

    # bgp.he.net seems to cache results, so add this header option
    headers = {
        "Cache-Control": "no-cache, no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0"
    }

    addresses = []
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            print(f"[WARNING] Failed to fetch ASN {asn}, HTTP {response.status_code}")
            return addresses

        try:
            soup = BeautifulSoup(response.text, "html.parser")
        except Exception as e:
            print(f"[ERROR] Error parsing HTML: {e}")
            return addresses

        # Find all tables dynamically
        tables = soup.find_all("table")
        #print ("HTML Table: ",tables)

        for table in tables:
            headers = [th.text.strip().lower() for th in table.find_all("th")]

            if "prefix" in headers and "description" in headers:
                for row in table.find_all("tr")[1:]:  # Skip header row
                    columns = row.find_all("td")
                    #print ("HTML Table columns: ",columns)
                    if len(columns) >= 2:
                        subnet = columns[0].text.strip()
                        if version == 6 and not ":" in subnet:
                            print (f"Error: invalid IPV6 subnet {subnet}") 
                            break
                        org_name = columns[1].text.strip()

                        if fuzzy_match(org_name, expected_org_name):
                            if subnet not in addresses:  # Check set instead of list
                                print (f"Org name match: adding subnet {subnet} for {org_name} (close match with {expected_org_name} ")
                                addresses.append(subnet)
                        #else:
                        #    # this is 'normal' for orgs sharing ASN with regional network
                        #    print (f"DEBUG: Org name mismatch: ASN {asn} org ({org_name}) is not similar to {expected_org_name}. Skipping this subnet")

        if addresses:
            print(f"[SUCCESS] Found {len(addresses)} subnets for ASN {asn}")
        else:
            print(f"[WARNING] No valid subnets found for ASN {asn}, or no name match.")

        return addresses

    except requests.exceptions.Timeout:
        print(f"[ERROR] Timeout when fetching ASN {asn}")
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Request error for ASN {asn}: {e}")

    return []


# Read CSV file to get organization names and ASNs
print(f"\n[INFO] Reading input CSV file: {INPUT_CSV}")
orgs = []
try:
    with open(INPUT_CSV, newline="", encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile)
        header = next(reader)  # Read header row

        for row in reader:
            print ("Processing row: ", row)
            org_name = row[0]  # Organization name
            asn = row[1]        # ASN
            asn = extract_numbers(asn)
            if asn.isdigit():    # Validate ASN
                orgs.append({"org_name": org_name, "asn": asn})
            else:
                print (f"Error: ASN {asn} invalid ")

    print(f"[INFO] Found {len(orgs)} organizations with ASNs.")

except FileNotFoundError:
    print(f"[ERROR] File {INPUT_CSV} not found! Please check the filename.")
    exit(1)

# Fetch subnets for each ASN
results = []
for index, org in enumerate(orgs):
    print(f"\n[PROCESSING] ({index+1}/{len(orgs)}) Fetching subnets for: {org['org_name']} (ASN: {org['asn']})")
    
    addresses = get_subnets(org["asn"], org["org_name"], version=4)
# not needed, for reasons I dont understand!!!
#    addresses += get_subnets(org["asn"], org["org_name"], version=6)
    
    if addresses:
        results.append({
            "addresses": addresses,
            "org_name": org["org_name"],
            "asn": org["asn"],
            "community": COMMUNITY  # Static community value
        })

    time.sleep(2)  # Delay to avoid being rate-limited

# Write results to JSON file
print(f"\n[INFO] Writing results to {OUTPUT_JSON}")
sorted_data = sorted(results, key=lambda x: x['asn'])

try:
    with open(OUTPUT_JSON, "w", encoding="utf-8") as jsonfile:
        json.dump(sorted_data, jsonfile, indent=4)
    print(f"[SUCCESS] JSON data saved to {OUTPUT_JSON}")

except Exception as e:
    print(f"[ERROR] Failed to write output file {OUTPUT_JSON}: {e}")

print(f"\n[INFO] Processing complete!")

