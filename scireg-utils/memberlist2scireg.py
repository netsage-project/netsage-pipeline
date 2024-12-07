#!/usr/bin/env python3

# converts old NetSage 'member list' file to new NetSage "Science Registry" JSON file.

# To Do / figure out:
#  - dont include at all if ASN exists? Do we need it in the Science Registry?
#  - maybe: Do lat/long lookup based on address?

import json
import argparse
import os
import re
from datetime import datetime
from collections import defaultdict
from ipwhois import IPWhois

def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Convert 'memberlist' files to scireg JSON format with member groups and ASN data.")
    parser.add_argument("-i", "--input", required=True, help="Input file name")
    return parser.parse_args()

def read_input_file(input_file):
    """Read and return the content of the input file."""
    with open(input_file, "r") as file:
        return file.read()


def parse_asn_list(input_data):
    """Parse @asn_list data from the input file."""
    for line in input_data.splitlines():
        line = line.strip()
        # Match lines with ASN list entries
        match = re.match(r"@asn_list\['(.+?)'\]\s*=\s*\[(\d+)\]", line)
        if match:
            group_name = match.group(1)
            asn = int(match.group(2))

    print ("Processing entries for memberlist with ASN: ", asn)
    return asn

def parse_members(input_data):
    """Parse @members data from the input file."""
    members = {}
    current_group = None

    for line in input_data.splitlines():
        line = line.strip()
        if line.startswith("@members["):
            # Extract the group name from the line
            current_group = line.split("[")[1].split("]")[0].strip("'\"")
            members[current_group] = {}
        elif "=>" in line and current_group:
            # Extract prefix and org_name
            prefix, org_name = line.split("=>")
            prefix = prefix.strip(' "')
            org_name = org_name.strip(' ",')

            # Add to the current group
            members[current_group][prefix] = org_name
        elif line == "}":
            current_group = None  # End of the current group

    return members

def lookup_asn(ip_subnet):
    """Look up the ASN for a given IP subnet using IPWhois."""
    try:
        ip = ip_subnet.split('/')[0]  # Use only the base IP for the lookup
        obj = IPWhois(ip)
        result = obj.lookup_rdap()
        #print (result)

        asn = result.get('asn', 'Unknown')
        network_cidr = result.get('network', {}).get('cidr', 'Unknown')
        address_fields = result.get('network', {}).get('remarks', [])
        entities = result.get('entities', [])

        # Extract contact name
        contact_name = "No contact name available"
        if entities:
            # Loop through entities to find the first contact name
            for entity in entities:
                entity_details = result.get('objects', {}).get(entity, {})
                if 'contact' in entity_details:
                    contact_name = entity_details['contact'].get('name', 'No contact name available')
                    contact_address_obj = entity_details['contact'].get('address', 'No contact address available')
                    contact_address = contact_address_obj[0]['value']
                    contact_address = contact_address.replace("\n", ", ")
                    #print ("Got contact_address: ", contact_address)
                    break  # Stop after finding the first contact

        print (f"whois data for subnet {ip_subnet}: ASN = {asn}, org name = {contact_name}")
        return { "asn": asn, "asn_contact": contact_name, "CIDR": network_cidr, "contact_address": contact_address }
    except Exception as e:
        print(f"ASN lookup failed for {ip_subnet}: {e}")
        return {"asn": "Unknown", "asn_contact": "Unknown", "CIDR": "Unknown", "status": "Unknown", "contact_address": "Unknown"}

def convert_to_scireg_format(members, asn):
    """Convert parsed members data to the scireg JSON format."""
    combined_data = defaultdict(lambda: {
        "addresses": [],
        "org_name": "",  # Placeholder to maintain order
        "member_of": "",  # Group name
        "discipline": "",  # Placeholder for discipline
        "latitude": "",    # Placeholder for latitude
        "longitude": "",   # Placeholder for longitude
        "resource_name": "",  # Placeholder for resource name
        "project_name": "",   # Empty as specified
        "contact_email": "unknown",  # Placeholder for email
        "asn_data": [],  # List of ASN data for each subnet
        "last_updated": datetime.now().strftime("%Y-%m-%d"),  # Today's date
        "scireg_id": 0  # Placeholder for ID
    })

    for group_name, entries in members.items():
        for prefix, org_name in entries.items():
            key = org_name
            combined_data[key]["addresses"].append(prefix)
            combined_data[key]["org_name"] = org_name
            combined_data[key]["member_of"] = group_name
            if not combined_data[key]["asn_data"]:  # Only append the first `asn_info`
                asn_info = lookup_asn(prefix)
                combined_data[key]["asn_data"].append(asn_info)


    # Add scireg_id and ensure field order matches the defaultdict
    output_list = []
    for scireg_id, org_data in enumerate(combined_data.values()):
        org_data["scireg_id"] = scireg_id
        # Convert to an ordered dictionary to preserve the field order
        ordered_org_data = {key: org_data[key] for key in combined_data.default_factory().keys()}
        #print ("ASN Data: ",ordered_org_data["asn_data"])
        asn_data = ordered_org_data["asn_data"]
        member_asn = asn_data[0].get('asn') if asn_data else None

        if asn != int(member_asn):
            print(f"  Note: member ASN {member_asn} is different from regional network ASN {asn}. Skip?? ")
        # XXX: Fixme! only add if its a different ASN ?
        output_list.append(ordered_org_data)
    return output_list

def write_output_file(output_file, output_list):
    """Write the converted data to the output file."""
    with open(output_file, "w") as f:
        json.dump(output_list, f, indent=4)
    print(f"Converted data saved to {output_file}")

def main():
    args = parse_arguments()
    input_file = args.input
    input_file_prefix = os.path.splitext(os.path.basename(input_file))[0]
    output_file = f"{input_file_prefix}.json"

    # Read, parse, convert, and write data
    input_data = read_input_file(input_file)
    asn = parse_asn_list(input_data)
    members = parse_members(input_data)
    output_list = convert_to_scireg_format(members, asn)
    write_output_file(output_file, output_list)

if __name__ == "__main__":
    main()

