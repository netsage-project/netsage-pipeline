#!/usr/bin/env python3

# verify subnets in community-*.json files using ASN from each entry, supporting both IPv4 and IPv6

# after running this, check community-mismatched.json for any entries that should be re-added

# Note: sometimes description in bgp.he.net is wrong. eg: https://bgp.he.net/AS53372#_prefixes
# To check what orgs are being removed, check the length:
#	jq 'length' community-verified.json
#       jq 'length' community-SCN.json
#  if they differ, check org_names
#  	grep org_name community-SCN.json > org1
#    	grep org_name community-verified.json > org2
#       diff -w org1 org2


import json
import requests
import sys
from bs4 import BeautifulSoup
from difflib import SequenceMatcher

json_file = 'community.json'
output_file = 'community-verified.json'
mismatch_output_file = 'community-mismatched.json'


# Load the JSON data from the file
print(f"Loading JSON data from {json_file}...")
with open(json_file, 'r') as file:
    data = json.load(file)
print(f"Loaded {len(data)} entries from JSON.")

def fetch_prefixes(asn, version=4):
    """Fetch prefixes for the given ASN from bgp.he.net, supporting both IPv4 and IPv6."""
    table_id = 'table_prefixes4' if version == 4 else 'table_prefixes6'
    url = f'https://bgp.he.net/AS{asn}#_prefixes{version}'
    print(f"Fetching prefix data from {url}...")
    response = requests.get(url)
    
    if response.status_code != 200:
        print(f"Failed to fetch data for ASN {asn}, status code: {response.status_code}")
        return {}
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Parse the prefixes and their descriptions
    prefix_table = soup.find('table', {'id': table_id})
    prefixes = {}
    
    if prefix_table:
        rows = prefix_table.find_all('tr')[1:]  # Skip the header row
        print(f"Found {len(rows)} prefix entries in the table for ASN {asn}.")
        #print(f"DEBUG: subnet rows from {url}: ", rows)
        for row in rows:
            cols = row.find_all('td')
            if len(cols) >= 2:
                prefix = cols[0].text.strip()
                description = cols[1].text.strip()
                prefixes[prefix] = description
                print(f"    Extracted prefix: {prefix}, description: {description}")
    else:
        print(f"WARNING: IPv{version} prefix table not found for ASN {asn}!")
    
    #print ("DEBUG: returning list for ASN {asn}: ", prefixes)
    return prefixes

def fuzzy_match(org1, org2, threshold=0.7):
    """Return True if org1 and org2 match with a similarity above the threshold."""
    ratio = SequenceMatcher(None, org1.lower(), org2.lower()).ratio()
    return ratio >= threshold

# Verify each address in the JSON data
print("Verifying JSON entries...")
mismatched_entries = []
filtered_data = []


for entry in data:
    #print ("\nDEBUG: checking entry: ", entry)
    org_name = entry.get('org_name', '')
    addresses = entry.get('addresses', [])
    asn = entry.get('asn')  # Fetch ASN from JSON entry
    
    if not asn:
        print(f"Skipping entry with missing ASN: {entry}")
        entry['verification'] = 'Missing ASN'
        mismatched_entries.append(entry)
        continue
    
    #print(f"\nChecking org: {org_name}, ASN: {asn}, addresses: {addresses}")
    print(f"\nChecking org: {org_name}, ASN: {asn}")
    prefixes_v4 = fetch_prefixes(asn, version=4)
    prefixes_v6 = fetch_prefixes(asn, version=6)
    
    valid_addresses = []
    print ("-------------------------")
    for address in addresses:
        print(f"  - Checking prefix: {address} for org '{org_name}'")
        prefix_org_list = prefixes_v4 if ':' not in address else prefixes_v6
        
        if address in prefix_org_list and not fuzzy_match(org_name, prefix_org_list[address]):
            mismatch_entry = {
                'org_name': org_name,
                'asn': asn,
                'address': address,
                'expected_org': prefix_org_list[address]
            }
            mismatched_entries.append(mismatch_entry)
            print(f"Subnet did not match: {mismatch_entry}")
        else:
            # confirm that address is in the list
            if address in prefix_org_list:
                print (f"name '{org_name}' fuzzy match for '{prefix_org_list[address]}', adding subnet {address}")
                valid_addresses.append(address)
            else:
                print (f"*** WARNING: subnet {address} not found. Assuming its shared by ASN owner, so including it. ***")
                valid_addresses.append(address)
    
    if valid_addresses:
        entry['addresses'] = valid_addresses
        filtered_data.append(entry)

# Save the updated JSON data to a new file
with open(output_file, 'w') as file:
    json.dump(filtered_data, file, indent=4)


# Save the mismatched JSON data to a separate file
with open(mismatch_output_file, 'w') as file:
    json.dump(mismatched_entries, file, indent=4)

print(f"\nVerification complete. Updated JSON saved as {output_file}")
print(f"Mismatched entries saved as {mismatch_output_file}")

