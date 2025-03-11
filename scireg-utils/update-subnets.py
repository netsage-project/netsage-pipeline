#!/usr/bin/env python3

# program to take a current community-*.json, and update the list of subnets from bgp.he.net
# Note that the org_name in BGP might be very different than the preferred NetSage org_name
#  so you will need to merge the output file results by hand.

import argparse
import json
import requests
import time
import sys
from bs4 import BeautifulSoup
from difflib import SequenceMatcher

def fuzzy_match(org1, org2, threshold=0.75):
    """Return True if org1 and org2 match with a similarity above the threshold."""
    ratio = SequenceMatcher(None, org1.lower(), org2.lower()).ratio()
    return ratio >= threshold

def fetch_prefixes(asn, expected_org_name):
    url = f"https://bgp.he.net/AS{asn}#_prefixes"
    headers = {
        "Cache-Control": "no-cache, no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0"
    }
    print(f"   Fetching prefix data from {url} ({expected_org_name})")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Error fetching ASN {asn}: {e}")
        return []
    
    soup = BeautifulSoup(response.text, 'html.parser')
    addresses = []

    tables = soup.find_all("table")
    for table in tables:
        headers = [th.text.strip().lower() for th in table.find_all("th")]

        if "prefix" in headers and "description" in headers:
            for row in table.find_all("tr")[1:]:  # Skip header row
                columns = row.find_all("td")
                #print ("HTML Table columns: ",columns)
                if len(columns) >= 2:
                    subnet = columns[0].text.strip()
                    org_name = columns[1].text.strip()

                    if fuzzy_match(org_name, expected_org_name):
                       if subnet not in addresses:  # Check set instead of list
                           #print (f"   Org name match: adding subnet {subnet} for {org_name} (close match with {expected_org_name} ")
                           addresses.append(subnet)
                    else:
                       print (f"   WARNING: BGP Org name '{org_name}' does not match '{expected_org_name}'")

    if not addresses:
        print(f"[WARNING] No valid subnets found for ASN {asn}, or no name match ({expected_org_name}).")
    #else:
    #    print(f"[SUCCESS] Found {len(addresses)} subnets for ASN {asn} ({expected_org_name})")

    return addresses

def update_json(input_file, output_file):
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    updated_data = []
    for entry in data:
        asn = entry.get("asn")
        if asn:
            print(f"Fetching prefixes for ASN {asn}...")
            new_prefixes = fetch_prefixes(asn, entry.get("org_name"))
            old_prefixes = set(entry.get("addresses", []))
            new_prefixes_set = set(new_prefixes)
            
            added_prefixes = new_prefixes_set - old_prefixes
            removed_prefixes = old_prefixes - new_prefixes_set
            
            if added_prefixes or removed_prefixes:
                print(f"Changes for ASN {asn}:")
                if added_prefixes:
                    print(f"  Added: {', '.join(added_prefixes)}")
                if removed_prefixes:
                    print(f"  Removed: {', '.join(removed_prefixes)}")
            else:
                print (f"   No change to list of subnets for ASN {asn}")
            
            updated_data.append({
                "org_name": entry["org_name"],
                "community": entry["community"],
                "asn": entry["asn"],
                "addresses": new_prefixes
            })
            
            time.sleep(1)  # Avoid overloading the server
    
    with open(output_file, 'w') as f:
        json.dump(updated_data, f, indent=4)
        f.write("\n")  # Ensure a newline at the end of the file
    print(f"Updated JSON written to {output_file}")

def main():
    parser = argparse.ArgumentParser(description="Update JSON with latest BGP prefixes from bgp.he.net")
    parser.add_argument("-i", "--input", required=True, help="Input JSON file")
    parser.add_argument("-o", "--output", required=True, help="Output JSON file")
    args = parser.parse_args()
    
    update_json(args.input, args.output)

if __name__ == "__main__":
    main()


