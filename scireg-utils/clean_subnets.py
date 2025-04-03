#!/usr/bin/env python3

import json
import argparse
import ipaddress

def remove_contained_subnets(subnet_list, org_name="(unknown org)"):
    """Remove subnets that are fully contained in any other subnet in the list, handling both IPv4 and IPv6."""
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
                    print(f"[{org_name}] Removing {net} because it is contained in {other}")
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

def process_file(input_file, output_file):
    with open(input_file, 'r') as f:
        data = json.load(f)

    if isinstance(data, dict):
        data = [data]

    for entry in data:
        if 'addresses' in entry:
            org_name = entry.get('org_name', '(unknown org)')
            entry['addresses'] = remove_contained_subnets(entry['addresses'], org_name=org_name)

    with open(output_file, 'w') as f:
        json.dump(data if len(data) > 1 else data[0], f, indent=4)

def main():
    parser = argparse.ArgumentParser(description="Remove subnets contained in larger ones (IPv4 + IPv6).")
    parser.add_argument('-i', '--input', required=True, help='Input JSON file')
    parser.add_argument('-o', '--output', required=True, help='Output JSON file')
    args = parser.parse_args()

    process_file(args.input, args.output)

if __name__ == '__main__':
    main()

