#!/usr/bin/env python3

# note: requires:
#    pip install requests beautifulsoup4

# simple script to scrape ipv4 and ipv6 subnet info from bgp.he.net based on the ASN

# note: currently filenames and community name is hardcoded below
# adjust these as needed in the code below
#    org_name = row[1]  # Organization name
#    asn = row[0]        # ASN
#
# also might need to adjust the fuzzy_match threshold if get not found Errors

# Note: for reasons I dont understand, the queary for url 'https://bgp.he.net/AS103#_prefixes' returns
# both V4 and V6 subnets, unlike what happens in a browser. WTF?
#
# Note: attempted to modify this to only grab subnets where "visibility" is over a threshold, but 
#  it did not work, as the visibility column on bgp.he.net is dynamically generated with javascript

import csv
import requests
import json
import time
import re
import sys
import argparse
import ipaddress
from bs4 import BeautifulSoup
from difflib import SequenceMatcher

BASE_URL = "https://bgp.he.net/"
COMMUNITY = "SoX"
DEFAULT_OUTPUT_JSON = "subnets.json"

def extract_numbers(s):
    match = re.search(r'\d+', s)
    return match.group() if match else ""

def fuzzy_match(org1, org2, threshold=0.7):
    return SequenceMatcher(None, org1.lower(), org2.lower()).ratio() >= threshold

def remove_contained_subnets(subnet_list, org_name="(unknown org)"):
    def parse_networks(subnets, version):
        return sorted(
            [ipaddress.ip_network(s, strict=False) for s in subnets if ipaddress.ip_network(s, strict=False).version == version],
            key=lambda x: x.prefixlen
        )

    def filter_subnets(networks, org_name):
        result = []
        for net in networks:
            contained = False
            for other in networks:
                if net != other and net.subnet_of(other):
                    print(f"   [{org_name}] Removing {net} because it is contained in {other}")
                    contained = True
                    break
            if not contained:
                result.append(str(net))
        return result

    ipv4_networks = parse_networks(subnet_list, 4)
    ipv6_networks = parse_networks(subnet_list, 6)

    cleaned_ipv4 = filter_subnets(ipv4_networks, org_name)
    cleaned_ipv6 = filter_subnets(ipv6_networks, org_name)

    return cleaned_ipv4 + cleaned_ipv6

def get_subnets(asn, expected_org_name):
    url = f"{BASE_URL}AS{asn}#_prefixes"
    print(f"[INFO] Fetching subnets for ASN {asn} from {url}")

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

        soup = BeautifulSoup(response.text, "html.parser")
        tables = soup.find_all("table")

        for table in tables:
            headers = [th.text.strip().lower() for th in table.find_all("th")]
            if "prefix" in headers and "description" in headers:
                for row in table.find_all("tr")[1:]:
                    columns = row.find_all("td")
                    if len(columns) >= 2:
                        subnet = columns[0].text.strip()
                        org_name = columns[1].text.strip()
                        if fuzzy_match(org_name, expected_org_name):
                            if subnet not in addresses:
                                addresses.append(subnet)

        return addresses
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Request error for ASN {asn}: {e}")
    return []

def get_all_org_subnets(asn):
    url = f"{BASE_URL}AS{asn}#_prefixes"
    print(f"[INFO] Fetching all subnets for ASN {asn} from {url}")

    headers = {
        "Cache-Control": "no-cache, no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0"
    }

    org_map = {}
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            print(f"[WARNING] Failed to fetch ASN {asn}, HTTP {response.status_code}")
            return []

        soup = BeautifulSoup(response.text, "html.parser")
        tables = soup.find_all("table")

        for table in tables:
            headers = [th.text.strip().lower() for th in table.find_all("th")]
            if "prefix" in headers and "description" in headers:
                for row in table.find_all("tr")[1:]:
                    columns = row.find_all("td")
                    if len(columns) >= 2:
                        subnet = columns[0].text.strip()
                        org_name = columns[1].text.strip()
                        if org_name:
                            org_map.setdefault(org_name, []).append(subnet)

        results = []
        for org_name, addresses in org_map.items():
            cleaned = remove_contained_subnets(addresses, org_name)
            results.append({
                "addresses": cleaned,
                "org_name": org_name,
                "asn": asn,
                "community": COMMUNITY
            })
        return results

    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Request error for ASN {asn}: {e}")
        return []

def read_csv(file_path):
    orgs = []
    try:
        with open(file_path, newline="", encoding="utf-8") as csvfile:
            reader = csv.reader(csvfile)
            header = next(reader)
            for row in reader:
                org_name = row[0]
                asn = extract_numbers(row[1])
                if asn.isdigit():
                    orgs.append({"org_name": org_name, "asn": asn})
                else:
                    print(f"[ERROR] Invalid ASN: {asn}")
        return orgs
    except FileNotFoundError:
        print(f"[ERROR] File {file_path} not found!")
        sys.exit(1)

def process_asns(orgs):
    results = []
    for index, org in enumerate(orgs):
        print(f"\n[PROCESSING] ({index+1}/{len(orgs)}) ASN: {org['asn']}, Org: {org['org_name']}")
        subnets = get_subnets(org["asn"], org["org_name"])
        if subnets:
            cleaned = remove_contained_subnets(subnets, org["org_name"])
            results.append({
                "addresses": cleaned,
                "org_name": org["org_name"],
                "asn": org["asn"],
                "community": COMMUNITY
            })
        else:
            print(f"  ERROR: No subnets found for org_name: {org['org_name']}, asn: {org['asn']}")
        time.sleep(2)
    return results

def save_results(results, output_file):
    try:
        with open(output_file, "w", encoding="utf-8") as jsonfile:
            json.dump(results, jsonfile, indent=4)
        print(f"[SUCCESS] Data saved to {output_file}")
    except Exception as e:
        print(f"[ERROR] Failed to write output file: {e}")

def main():
    parser = argparse.ArgumentParser(description="Scrape subnets from bgp.he.net and remove contained ones.")
    parser.add_argument("-a", "--asn", type=str, help="Lookup a single ASN")
    parser.add_argument("-i", "--input", type=str, help="CSV file with list of ASNs")
    parser.add_argument("-o", "--output", type=str, default=DEFAULT_OUTPUT_JSON, help="Output JSON file")
    args = parser.parse_args()

    results = []
    if args.asn:
        results = get_all_org_subnets(extract_numbers(args.asn))
    elif args.input:
        orgs = read_csv(args.input)
        results = process_asns(orgs)
    else:
        print("[ERROR] You must provide either -a ASN or -i CSV file.")
        sys.exit(1)

    save_results(results, args.output)
    print(f"Done (community = {COMMUNITY})\n")

if __name__ == "__main__":
    main()


