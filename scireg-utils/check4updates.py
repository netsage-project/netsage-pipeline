#!/usr/bin/env python3

# input a JSON comunity file, and compare with bgp.he.net for any updates

import json
import requests
import argparse
import time
import ipaddress
from bs4 import BeautifulSoup
from difflib import SequenceMatcher

BASE_URL = "https://bgp.he.net/"
FUZZY_MATCH = 0.9

def fuzzy_match(org1, org2, threshold=FUZZY_MATCH):
    return SequenceMatcher(None, org1.lower(), org2.lower()).ratio() >= threshold

def collapse_subnet_dict(subnet_dict):
    """Collapse IPv4 and IPv6 subnets separately while keeping descriptions (first match wins)."""
    ipv4 = []
    ipv6 = []

    for s, desc in subnet_dict.items():
        try:
            net = ipaddress.ip_network(s, strict=False)
            if net.version == 4:
                ipv4.append((net, desc))
            else:
                ipv6.append((net, desc))
        except ValueError:
            print(f"[WARNING] Skipping invalid subnet: {s}")

    def collapse_group(group):
        collapsed_map = {}
        raw_nets = [net for net, _ in group]
        collapsed = ipaddress.collapse_addresses(raw_nets)
        for cnet in collapsed:
            # use the first description found from original nets that fit
            for net, desc in group:
                if net.subnet_of(cnet):
                    collapsed_map[str(cnet)] = desc
                    break
        return collapsed_map

    collapsed_ipv4 = collapse_group(ipv4)
    collapsed_ipv6 = collapse_group(ipv6)

    return {**collapsed_ipv4, **collapsed_ipv6}

def collapse_list(subnets):
    """Collapse list of mixed v4/v6 subnets."""
    ipv4 = []
    ipv6 = []

    for s in subnets:
        try:
            net = ipaddress.ip_network(s, strict=False)
            if net.version == 4:
                ipv4.append(net)
            else:
                ipv6.append(net)
        except ValueError:
            print(f"[WARNING] Skipping invalid stored subnet: {s}")

    collapsed = list(ipaddress.collapse_addresses(ipv4)) + list(ipaddress.collapse_addresses(ipv6))
    return sorted(str(net) for net in collapsed)

def get_current_subnets(asn, expected_org_name):
    url = f"{BASE_URL}AS{asn}#_prefixes"
    print(f"\n[INFO] Checking ASN {asn} for {expected_org_name}")

    headers = {
        "Cache-Control": "no-cache, no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0"
    }

    raw_subnets = {}
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            print(f"  [ERROR] HTTP {response.status_code} for ASN {asn}")
            return {}

        soup = BeautifulSoup(response.text, "html.parser")
        tables = soup.find_all("table")

        for table in tables:
            headers = [th.text.strip().lower() for th in table.find_all("th")]
            if "prefix" in headers and ("description" in headers or "name" in headers):
                for row in table.find_all("tr")[1:]:
                    columns = row.find_all("td")
                    if len(columns) >= 2:
                        subnet = columns[0].text.strip()
                        description = columns[1].text.strip()
                        name = columns[2].text.strip() if len(columns) >= 3 else ""

                        if (
                            fuzzy_match(description, expected_org_name) or
                            fuzzy_match(name, expected_org_name)
                        ):
                            raw_subnets[subnet] = description

        return collapse_subnet_dict(raw_subnets)
    except requests.exceptions.RequestException as e:
        print(f"  [ERROR] Request error for ASN {asn}: {e}")
        return {}

def compare_subnet_sets(original_list, current_dict):
    current_set = set(current_dict.keys())
    original_set = set(collapse_list(original_list))

    added = sorted(current_set - original_set)
    removed = sorted(original_set - current_set)

    return added, removed

def main():
    parser = argparse.ArgumentParser(description="Compare stored subnets with live data from bgp.he.net")
    parser.add_argument("-i", "--input", required=True, help="Input JSON file from previous run")
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as infile:
        data = json.load(infile)

    for entry in data:
        org_name = entry.get("org_name", "(unknown)")
        asn = entry.get("asn")
        stored_subnets = entry.get("addresses", [])

        current_subnet_map = get_current_subnets(asn, org_name)
        added, removed = compare_subnet_sets(stored_subnets, current_subnet_map)

        if not added and not removed:
            print(f"  [✓] No changes for {org_name} (ASN {asn})")
        else:
            print(f"  [!] Differences for {org_name} (ASN {asn}):")
            for subnet in added:
                desc = current_subnet_map.get(subnet, "")
                print(f"    + {subnet:<18}  ({desc})")
            for subnet in removed:
                print(f"    - {subnet}")
        time.sleep(2)

    print ("\nDone.\n")
    print ("Note: before adding missing subnets to JSON file, check bgp.he.net to make sure visability is 100")

if __name__ == "__main__":
    main()

