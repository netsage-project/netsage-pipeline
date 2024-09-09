#!/usr/bin/env python3

# read old style of Science Registry JSON, and convert to new format
# also create csv file for for adding to a Google Sheet for editing
#
# this program strips out all of the following old scireg data:
#   all /32s (single hosts)
#   all perfSONAR hosts
#
# TODO: handle IPV6 better!
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

# do 'pip install python-whois' for this
# to get contact address from whois
#import whois

ping_succeeded = 0
ping_failed = 0

# set this to include all /32s in old Science Registry
# also set check_ping to only include pingable hosts
include_single_hosts = 0
include_single_hosts = 1

# this needs more testing: do hostname lookups to see what they are
combine24 = 1
#combine24 = 0



import ipaddress
from collections import defaultdict

# Function to lookup hostname from an IP address (assumes `lookup_ip` exists)
def lookup_ip(ip_address):
    # You can implement or modify this function as needed.
    # For now, let's just mock the lookup to return the IP as the "hostname"
    try:
        hostname = socket.gethostbyaddr(ip_address)[0]
        return hostname
    except (socket.herror, socket.gaierror):
        return ip_address + "; Unknown"

def combine_to_24(subnets):
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
            network_groups[parent_net].append(ip_net)

            # Lookup the hostname for the /32 address
            hostname = lookup_ip(str(ip_net.network_address))
            hostnames_by_24[parent_net].append(hostname)
        else:
            # If it's not /32, add it directly to the result (optional handling)
            network_groups[ip_net].append(ip_net)

    # List to store the final result
    result = []

    # Loop through each /24 group and decide whether to combine or not
    for parent_net, ip_list in network_groups.items():
        if len(ip_list) > 1:
            # Combine into /24 if more than one /32 in the same /24 network
            result.append(str(parent_net))

            # Print the list of hostnames for the combined /32 addresses
            print(f"  Combined /32 addresses into {parent_net}:")
            for hostname in hostnames_by_24[parent_net]:
                print(f"    Hostname: {hostname}")
        else:
            # Otherwise, keep the individual subnet
            result.append(str(ip_list[0]))

    # Add the IPv6 subnets to the result as they are
    result.extend(str(subnet) for subnet in ipv6_subnets)

    return result

def ping_host(address):
    # checks if ping works, or port 22 or 443 are open
    global ping_succeeded
    global ping_failed

    if address.endswith("/32"):
        ip = address.split("/")[0]
        print("checking host:", ip)
        try:
            ping_output = subprocess.check_output(["ping", "-c", "1", '-W', '1', ip], stderr=subprocess.DEVNULL)
            #print("   ping succeeded.")
            ping_succeeded += 1
            return 1  # Ping succeeded
        except subprocess.CalledProcessError:
            #print("   ping failed.")
            # if ping fails, also check if 443 or 22 are open, in case ICMP is blocked
            ports_to_check = [22, 443]
            for port in ports_to_check:
                #print("checking port:", port, "on host:", ip)
                try:
                    nc_output = subprocess.check_output(["nc", "-zv", "-w1", ip, str(port)], stderr=subprocess.DEVNULL, timeout=1)
                    #print("   port check succeeded:", port)
                    ping_succeeded += 1
                    return 1  # Port is open
                except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                    #print("   port check failed.")
                    ping_failed += 1
            ping_failed += 1
            print(f"  host {ip} not up")
            return 0  # All checks failed, both ping and ports
    else:
        return 2  # For non /32 addresses, set is_pingable to 2

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
        total_cnt += 1
        org_name = item.get("org_name", "")
        addresses = item.get("addresses", [])

        # combine org_name and org_abbr
        org_name = item.get("org_name", "")
        org_abbr = item.get("org_abbr", "")
        if org_abbr is not None and org_name is not None and org_abbr != "" and org_name != "" and org_abbr not in org_name:
           #print (f"XXX: adding {org_abbr} to {org_name}")
           org_name += f" ({org_abbr})" # add org_abbr to end of org_name if not already there

        # combine prog_name and prog_abbr
        #if proj_abbr is not None and proj_name is not None and proj_abbr != "" and proj_name != "" and proj_abbr not in proj_name:
        #   proj_name += f" ({proj_abbr})" # add proj_abbr to end of proj_name if not already there
        #   #print (f"    updating Project name with proj_abbr. New Name: {proj_name}")

        role = item.get("role", "")
        if role == None:
            role = ""
        # add previous 'role' to resource name
        if role != "Unknown" and role != "" and role != None:
            resource_name = item.get("resource", "") + " - " + role
        else:
            resource_name = item.get("resource", "") 

        discipline = item.get("discipline", "")

        if combine24 and len(addresses) > 1:
            print (f"\n{filtered_cnt}: Combining subnets for ORG: {org_name}", addresses)
            combined_subnets = combine_to_24(addresses)
            if len(combined_subnets) < len(addresses):
                print (f"{filtered_cnt}: Converted subnet list: ", addresses)
                print ("     to new subnet list: ", combined_subnets)
            else:
                print (f"{filtered_cnt}: Leaving subnet list as is: ", combined_subnets)
            addresses = combined_subnets

        new_subnets = []
        for address in addresses:
            #print(f"{filtered_cnt}: checking address: ", address)
            is_pingable = 1   # assume pingable by default
            if address.endswith("/32"):
                if include_single_hosts:
                    if discipline == "CS.Network Testing and Monitoring" and proj_name != "Data Mobility Exhibition":  
			 # skip perfSONAR hosts: more are out of date.
                         #print (f"  skipping perfSONAR host {address}")
                         skip_cnt += 1
                    elif check_ping:
                         is_pingable = ping_host(address)
                         if is_pingable:
                             print (f"  host {address} is up")
                    if is_pingable > 0:
                          num_subnets += 1  
                          #print (f"{filtered_cnt}: adding /32 address {address} to new subnets array")
                          new_subnets.append(address)
                else:
                    skip_cnt += 1
                    continue  # skip /32 and continue with next item
            else:
                num_subnets += 1  
                #print (f"{filtered_cnt}: adding subnet {address} to new subnets array")
                new_subnets.append(address)

        if include_single_hosts and len(new_subnets) == 0:
            print ("error: number of subnets is zero. This should not happen. exiting")
            sys.exit()

        # for any of the following DOE sites, set engage@es.net as the contact email
        if "ESnet" in org_name or "FNAL" in org_name or "BNL" in org_name or \
             "ORNL" in org_name or "Fermi" in org_name or "NERSC" in org_name or \
             "ANL" in org_name or "LBL" in org_name or "LBNL" in org_name or "LLNL" in org_name:
            contact_email = "engage@es.net"
            #print (f"Setting contact email to {contact_email} for Org {org_name}")
        else:
            contact_email = "unknown"

        if len(new_subnets) > 0: # only if have at least 1 subnet
            projects = item.get("projects", []) # projects is an array, but almost never has more than 1 entry
            proj_name = get_project_name(projects)
            if len(projects) > 1:
                print(f"  {filtered_cnt}: New combined project name string: {proj_name}")
                print(f"        Subnet list: ", new_subnets)

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

    print (f"\nProcessed {total_cnt} science registry entries; skipped {skip_cnt} /32 hosts")

    with open(output_json_file, 'w') as f:
        json.dump(filtered_data, f, indent=2)
    print (f"\nWrote {len(filtered_data)} entries ({num_subnets} subnets) to file {output_json_file} \n")

# XXX: revisit later
#    with open(skipped_json_file, 'w') as f:
#        json.dump(skipped_data, f, indent=2)
#    print (f"Wrote {len(skipped_data)} entries to file {skipped_json_file} \n")

    return (filtered_cnt, skip_cnt, filtered_data)

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
    parser.add_argument("-p", "--ping", action="store_true", help="Check if host is reachable")
    args = parser.parse_args()

    input_file = args.input
    output_json_file = args.output
    output_csv = args.csv
    check_ping = args.ping

    skipped_json_file = "skipped_entries.json"

    if check_ping:
        print ("Will check if host is pingable before adding to output file")

    cnt,skip_cnt,data = filter_fields(input_file, output_json_file,skipped_json_file,check_ping)

    # Write data to CSV
    # Sort data by org_name for csv file
    data.sort(key=lambda x: x["org_name"])
    write_to_csv(data, output_csv)

    if check_ping:
       total_32s = ping_succeeded + ping_failed
       print("\nFound %d valid subnet entries, including %d /32s, %d are pingable, %d are not" % (cnt, total_32s, ping_succeeded, ping_failed))
    print("Results written to files: JSON - %s, CSV - %s" % (output_json_file, output_csv))
    #print("%d entries skipped. See %s" % (skip_cnt, skipped_json_file))
    print("Done.")



