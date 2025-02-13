#!/usr/bin/env python3

# note: requires:
#    pip install requests beautifulsoup4

# simple script to script ipv4 and ipv6 subnet info from bgp.he.net based on the ASN

# note: currently filenames and community name is hardcoded below

import csv
import requests
import json
import time
import re
from bs4 import BeautifulSoup

# File Paths
INPUT_CSV = "organizations_with_asn.csv"
OUTPUT_JSON = "subnets.json"
BASE_URL = "https://bgp.he.net/"
COMMUNITY = "SCN"  # Set static community value

################################################################

def extract_numbers(s):
    match = re.search(r'\d+', s)  # Find the first sequence of digits
    return match.group() if match else None

# Function to get valid subnets (IPv4 & IPv6) for a given ASN
def get_subnets(asn):
    url = f"{BASE_URL}AS{asn}#_prefixes"
    print(f"[INFO] Fetching subnets for ASN {asn} from {url}")

    try:
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            print(f"[WARNING] Failed to fetch ASN {asn}, HTTP {response.status_code}")
            return []

        soup = BeautifulSoup(response.text, "html.parser")

        # Find all tables dynamically
        tables = soup.find_all("table")
#        print(f"[DEBUG] Found {len(tables)} tables on page for ASN {asn}")

        addresses = []

        # Find the correct table dynamically and extract subnets
        for table in tables:
            headers = [th.text.strip().lower() for th in table.find_all("th")]
            if "prefix" in headers:
#                print(f"[DEBUG] Found subnet table for ASN {asn}")

                for row in table.find_all("tr")[1:]:  # Skip header row
                    columns = row.find_all("td")
                    if columns:
                        subnet = columns[0].text.strip()
                        
                        # Validate subnet format (ignore "Loading Prefixes..." or invalid data)
                        if "/" in subnet and not subnet.lower().startswith("loading"):
                            addresses.append(subnet)

        if addresses:
            print(f"[SUCCESS] Found {len(addresses)} subnets for ASN {asn}")
        else:
            print(f"[WARNING] No valid subnets found for ASN {asn}, but page loaded successfully.")

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
            org_name = row[1]  # Organization name
            asn = row[0]        # ASN
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
    
    addresses = get_subnets(org["asn"])
    
    if addresses:
        results.append({
            "addresses": addresses,
            "org_name": org["org_name"],
            "asn": org["asn"],
            "community": COMMUNITY  # Static community value
        })

    time.sleep(3)  # Delay to avoid being rate-limited

# Write results to JSON file
print(f"\n[INFO] Writing results to {OUTPUT_JSON}")
try:
    with open(OUTPUT_JSON, "w", encoding="utf-8") as jsonfile:
        json.dump(results, jsonfile, indent=4)
    print(f"[SUCCESS] JSON data saved to {OUTPUT_JSON}")

except Exception as e:
    print(f"[ERROR] Failed to write output file {OUTPUT_JSON}: {e}")

print(f"\n[INFO] Processing complete!")


