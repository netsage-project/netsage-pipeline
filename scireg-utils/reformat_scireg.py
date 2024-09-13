#!/usr/bin/env python3

# read old style of Science Registry JSON, and convert to new format
# also create csv file for for adding to a Google Sheet for editing
#
# this program strips out all of the following old scireg data:
#   all /32s (single hosts)
#   all perfSONAR hosts
#
# other options (set via globals below)
#  combine24: combine mutiple /32s into a single /24. Note: there is no way to tell if its actually a /24
#     - current default is TRUE
#
# TODO: combine multiple IPV6 /128 into a /64 
#

import json
import subprocess
import csv
import re
import sys
import ipaddress
import socket
import argparse
from collections import defaultdict

#globals

ping_succeeded = 0
ping_failed = 0

# if multiple /32s, combine into a single /24
combine24 = 1

# Function to lookup hostname from an IP address (assumes `lookup_ip` exists)
def lookup_ip(ip_address):
    # You can implement or modify this function as needed.
    # For now, let's just mock the lookup to return the IP as the "hostname"
    try:
        hostname = socket.gethostbyaddr(ip_address)[0]
        return hostname
    except (socket.herror, socket.gaierror):
        return ip_address + "; Unknown"

def combine_to_24(subnets,id):
    # Dictionary to store the /32 subnets grouped by their /24 network
    network_groups = defaultdict(list)
    # List to store all IPv6 subnets
    ipv6_subnets = []

    # Dictionary to store hostnames for /32 addresses
    hostnames_by_24 = defaultdict(list)

    # Group subnets by their parent /24 network
    for subnet in subnets:
        ip_net = ipaddress.ip_network(subnet)

        # Skip if it's an IPv6 address
        if isinstance(ip_net, ipaddress.IPv6Network):
            ipv6_subnets.append(ip_net)
            continue

        # Ensure we are working with a /32 network
        if ip_net.prefixlen == 32:
            parent_net = ip_net.supernet(new_prefix=24)
            ip_str = str(ip_net.network_address)

            # Check if the host is pingable before adding
            if ping_host(ip_str, check_ping, id):
                #print (f"host at address {ip_str} is up")
                network_groups[parent_net].append(ip_net)

                # Lookup the hostname for the /32 address
                hostname = lookup_ip(ip_str)  # Assuming `lookup_ip` is defined elsewhere
                hostnames_by_24[parent_net].append(hostname)
            else:
                print(f"{id}:  Skipping {ip_str} since it is not reachable.")

        else:
            # If it's not /32, add it to the list of subnets
            network_groups[ip_net].append(ip_net)

    # List to store the final result
    result = []

    # Loop through each /24 group and decide whether to combine or not
    for parent_net, ip_list in network_groups.items():
        if len(ip_list) > 1:
            # Combine into /24 if more than one /32 in the same /24 network
            result.append(str(parent_net))

            # Print the list of hostnames for the combined /32 addresses
            print(f"{id}: Combined /32 addresses into {parent_net}:")
            for hostname in hostnames_by_24[parent_net]:
                print(f"    Hostname: {hostname}")
        else:
            # Otherwise, keep the individual subnet
            result.append(str(ip_list[0]))

    # Add the IPv6 subnets to the result as they are
    result.extend(str(subnet) for subnet in ipv6_subnets)

    return result

def ping_host(address, check_ping, id):
    # checks if ping works, or port 22 or 443 are open
    global ping_succeeded
    global ping_failed

    if not check_ping:  # just return 1 if not checking
        #print (f"{id}: skipping ping check for address: ", address)
        return 1

    print (f"{id}: Checking if host {address} ({lookup_ip(address)}) is up.")
    try:
        ping_output = subprocess.check_output(["ping", "-c", "1", '-W', '1', address], stderr=subprocess.DEVNULL)
        #print("   ping succeeded.")
        ping_succeeded += 1
        return 1  # Ping succeeded
    except subprocess.CalledProcessError:
        #print("   ping failed.")
        # if ping fails, also check if 443 or 22 are open, in case ICMP is blocked
        # Xrootd port is usually 1094, so checking that too
        ports_to_check = [22, 443, 1094]
        for port in ports_to_check:
            #print("checking port:", port, "on host:", address)
            try:
                nc_output = subprocess.check_output(["nc", "-zv", "-w1", address, str(port)], stderr=subprocess.DEVNULL, timeout=1)
                print(f"   {address} port check succeeded:", port)
                ping_succeeded += 1
                return 1  # Port is open
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                #print(f"   port {port} check failed.")
                continue
        # if got this far, host is down
        ping_failed += 1
        print(f"     host {address} not up")
        return 0  # All checks failed, both ping and ports

def extract_ip_subnet(ip_address):
    # gets the first part of ipaddress: X.X.X.0
    try:
        ip_network = ipaddress.ip_network(ip_address, strict=False)
        # Get the network address and convert it to string
        network_address = str(ip_network.network_address)
        # Replace the last octet with 0
        network_address_parts = network_address.split('.')
        network_address_parts[-1] = '0'
        return '.'.join(network_address_parts)

    except ValueError:
        return None


def get_project_name(projects):
    project_names = []

    # Loop through each project and handle the concatenation of project_name and prog_abbr
    for project in projects:
        project_name = project.get('project_name', '')
        project_abbr = project.get('project_abbr', '') 
        if project_name and project_abbr and project_name != project_abbr:
              full_project_name = f"{project_name} ({project_abbr})"
              #print (f"   Adding project_abbr {project_abbr} to {project_name}: new name: {full_project_name} ")
        else:
              full_project_name = project_name
               
        # Add the full project name (with or without prog_abbr) to the list
        if full_project_name:
              project_names.append(full_project_name)

    # Combine all project names into a single string separated by ' ; '
    if (project_names):
        proj_name = " ; ".join(project_names)
    else:
        proj_name = ''

    return proj_name


def filter_fields(input_file, output_json_file, skipped_json_file, check_ping):
    filtered_data = []
    skipped_data = []
    subnet_address_count = {}  # Dictionary to store address count for each subnet (x.x.x.0)
    filtered_cnt = 0
    skip_cnt = 0
    total_cnt = 0
    num_subnets = 0

    with open(input_file, 'r') as f:
        data = json.load(f)

    for item in data:
        print ("--------------")
        total_cnt += 1
        org_name = item.get("org_name", "")
        addresses = item.get("addresses", [])

        # combine org_name and org_abbr
        org_name = item.get("org_name", "")
        org_abbr = item.get("org_abbr", "")
        if org_abbr is not None and org_name is not None and org_abbr != "" and org_name != "" and org_abbr not in org_name:
           #print (f"XXX: adding {org_abbr} to {org_name}")
           org_name += f" ({org_abbr})" # add org_abbr to end of org_name if not already there

        print (f"{total_cnt}: Checking subnets for org {org_name}", addresses)
        role = item.get("role", "")
        if role == None:
            role = ""
        # add previous 'role' to resource name
        if role != "Unknown" and role != "" and role != None:
            resource_name = item.get("resource", "") + " - " + role
        else:
            resource_name = item.get("resource", "") 

        discipline = item.get("discipline", "")

        orig_addresses = addresses  # keep a copy of orginal subnet list for 'skipped' file
        if combine24 and len(addresses) > 1:
            print (f"\n{total_cnt}: Combining subnets for ORG: {org_name}", addresses)
            combined_subnets = combine_to_24(addresses, total_cnt)
            if len(combined_subnets) > 0:
                if len(combined_subnets) < len(addresses):
                    print (f"{total_cnt}: Converted subnet list: ", addresses)
                    print ("     to new subnet list: ", combined_subnets)
                else:
                    print (f"{total_cnt}: Leaving subnet list as is: ", combined_subnets)
            else:
                print (f"{total_cnt}: No valid addresses for this organization ")
            addresses = combined_subnets

        new_subnets = []
        up = "" # initialize, flag for /32 up/down
        for address in addresses:
            #print(f"{total_cnt}: checking address: ", address)
            if address.endswith("/32"):
                is_pingable = 1   # assume pingable by default
                # only keep /32 addresses that are pingable. Note that even with combine24, single /32s may still exist
                if discipline == "CS.Network Testing and Monitoring" and proj_name != "Data Mobility Exhibition":  
		    # skip perfSONAR hosts: most are out of date, and some overlap with DTNs.
                    print (f"{total_cnt}:  skipping perfSONAR host {address}")
                    skip_cnt += 1
                elif check_ping:
                    if len(orig_addresses) == 1: # then did not get checked by combine_to_24 routine
                        is_pingable = ping_host(address, check_ping, total_cnt)
                if is_pingable:
                    num_subnets += 1  
                    #print (f"{total_cnt}: adding /32 address {address} to new subnets array")
                    new_subnets.append(address)
                else:
                    skip_cnt += 1
                    up = "False"
                    print (f"{total_cnt}: Skipping /32 address {address} for org {org_name}, host is down")
                    continue  # skip /32 and continue with next item
            else:
                num_subnets += 1  
                print (f"{total_cnt}:   adding subnet {address} to new subnets array")
                new_subnets.append(address)

        # for any of the following DOE sites, set engage@es.net as the contact email
        if "ESnet" in org_name or "FNAL" in org_name or "BNL" in org_name or \
             "ORNL" in org_name or "Fermi" in org_name or "NERSC" in org_name or \
             "ANL" in org_name or "LBL" in org_name or "LBNL" in org_name or "LLNL" in org_name:
            contact_email = "engage@es.net"
            #print (f"Setting contact email to {contact_email} for Org {org_name}")
        else:
            contact_email = "unknown"

        projects = item.get("projects", []) # projects is an array, but almost never has more than 1 entry
        proj_name = get_project_name(projects)
        if len(projects) > 1:
            print(f"  {total_cnt}: New combined project name string: {proj_name}")
            print(f"        Subnet list: ", new_subnets)

        if len(new_subnets) > 0: # only if have at least 1 subnet
            filtered_item = {
                "addresses": new_subnets,
                "org_name": org_name,
                "discipline": item.get("discipline", ""),
                "latitude": item.get("latitude", ""),
                "longitude": item.get("longitude", ""),
                "resource_name": resource_name,
                "project_name": proj_name,
                "scireg_id": filtered_cnt,
                "contact_email": contact_email,
                "last_updated": "unknown",
            }

            filtered_cnt+=1
            filtered_data.append(filtered_item)
        else:
            if up == "": # only set if not already set above
                # with current logic, this should always be 'false'
                if len(addresses) == 0: # this means all /32s not up
                    up = "False"
                else:
                    up = "True"
            skipped_item = {
                "addresses": orig_addresses,
                "org_name": org_name,
                "discipline": item.get("discipline", ""),
                "latitude": item.get("latitude", ""),
                "longitude": item.get("longitude", ""),
                "resource_name": resource_name,
                "project_name": proj_name,
                "contact_email": contact_email,
                "last_updated": "unknown",
                "is_up": up,
            }
            #print ("adding to list of skipped entries: ", skipped_item)
            skipped_data.append(skipped_item)

        print (f"{total_cnt}: Done with this entry for org {org_name}\n")

        # to speed up debugging
        #if total_cnt > 10:
        #   break

    print (f"\nProcessed {total_cnt} science registry entries; skipped {skip_cnt} /32 hosts")

    with open(output_json_file, 'w') as f:
        json.dump(filtered_data, f, indent=2)
    print (f"\nWrote {len(filtered_data)} entries ({num_subnets} subnets) to file {output_json_file} \n")

    with open(skipped_json_file, 'w') as f:
        json.dump(skipped_data, f, indent=2)
    print (f"Wrote {len(skipped_data)} entries to file {skipped_json_file} \n")

    return (filtered_cnt, skip_cnt, filtered_data, skipped_data)

# Function to write data to CSV
def write_to_csv(data, output_csv):
    with open(output_csv, 'w', newline='') as csvfile:
        fieldnames = ['address', 'org_name', 'discipline', 'resource_name', 'project_name', 'contact_email', 'scireg_id']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()

        for entry in data:
            addresses = entry.get('addresses', '')
            for address in addresses:
                org_name = entry.get('org_name', '')
                discipline = entry.get('discipline', '')
                resource_name = entry.get('resource_name', '')
                if resource_name:
                     resource_name = resource_name.strip()
                project_name = entry.get('project_name', '')
                if project_name:
                     project_name = resource_name.strip()
                contact_email = entry.get('contact_email', '')
                scireg_id = entry.get('scireg_id', '')

                writer.writerow({
                        'address': address,
                        'org_name': org_name,
                        'discipline': discipline,
                        'resource_name': resource_name,
                        'project_name': project_name,
                        'contact_email': contact_email,
                        'scireg_id': scireg_id,
                })



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process Science Registry JSON files.")
    parser.add_argument("-i", "--input", default="scireg.json", help="Input JSON file (default = scireg.json)")
    parser.add_argument("-o", "--output", default="newScireg.json", help="Output JSON file (default = newScireg.json)")
    parser.add_argument("-c", "--csv", default = "scireg.csv", help="Output CSV file")
    parser.add_argument("-s", "--csv_skip", default = "skipped.csv", help="Output CSV file of skipped entries")
    parser.add_argument("-p", "--ping", action="store_true", help="Check if host is reachable")
    args = parser.parse_args()

    input_file = args.input
    output_json_file = args.output
    output_csv = args.csv
    skipped_csv = args.csv_skip
    check_ping = args.ping

    skipped_json_file = "skipped_entries.json"

    if check_ping:
        print ("Will check if host is pingable before adding to output file")

    cnt,skip_cnt,data,skipped_data = filter_fields(input_file, output_json_file,skipped_json_file,check_ping)

    # Write data to CSV
    # Sort data by org_name for csv file
    data.sort(key=lambda x: x["org_name"])
    write_to_csv(data, output_csv)
    write_to_csv(skipped_data, skipped_csv)

    if check_ping:
       total_32s = ping_succeeded + ping_failed
       print("\nFound %d valid subnet entries, including %d /32s, %d are pingable, %d are not" % (cnt, total_32s, ping_succeeded, ping_failed))
    print("Results written to files: JSON - %s, CSV - %s" % (output_json_file, output_csv))
    print("%d entries skipped. See %s" % (skip_cnt, skipped_json_file))
    print("Done.")



