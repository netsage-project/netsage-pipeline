#!/usr/bin/env python3

# read old style of Science Registry JSON, and convert to new format
# also create csv file for for adding to a Google Sheet for editing
#
# this program strips out all of the following old scireg data:
#   all /32s (single hosts)
#   all perfSONAR hosts
#

import json
import subprocess
import csv
import re
import ipaddress
import argparse
# do 'pip install python-whois' for this
#import whois

ping_succeeded = 0
ping_failed = 0

def ping_host(address):
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


def filter_fields(input_file, output_json_file, skipped_json_file, check_ping):
    scireg_id = 1  # give each entry a unique ID 
    filtered_data = []
    skipped_data = []
    subnet_address_count = {}  # Dictionary to store address count for each subnet (x.x.x.0)
    filtered_cnt = 0
    skip_cnt = 0
    total_cnt = 0

    with open(input_file, 'r') as f:
        data = json.load(f)

    for item in data:
        total_cnt += 1
        org_name = item.get("org_name", "")

        num_subnets = 0
        new_subnets = []
        old_subnets = item.get("addresses", [])
        for address in item.get("addresses", []):
            is_pingable = 0
            if address.endswith("/32"):
                if check_ping:
                    is_pingable = ping_host(address)
                    if address.endswith("/32"):
                        print ("  host is up")
            else:
                is_pingable = 2
            # XXX for now, just grab anything not a /32 XXX
            if is_pingable == 2:
               num_subnets += 1  # count number of subnets that are not a single host /32
               #print (f"adding address {address} to new subnets array")
               new_subnets.append(address)

        if num_subnets == 0:
            # XXX: next version will save /32s to a separate file...
            skip_cnt += 1
            continue  # for now, skip and continue with next item

        projects = item.get("projects", []) # projects is an array, but almost never has more than 1 entry
        try:
            proj_name = projects[0]['project_name']
        except:
            proj_name = ""
        try:
            proj_abbr = projects[0]['project_abbr']
        except:
            proj_abbr = ""

        # combine org_name and org_abbr
        org_name = item.get("org_name", "")
        org_abbr = item.get("org_abbr", "")
        if org_abbr is not None and org_name is not None and org_abbr != "" and org_name != "" and org_abbr not in org_name:
           #print (f"XXX: adding {org_abbr} to {org_name}")
           org_name += f" ({org_abbr})" # add org_abbr to end of org_name if not already there

        # combine prog_name and prog_abbr
        if proj_abbr is not None and proj_name is not None and proj_abbr != "" and proj_name != "" and proj_abbr not in proj_name:
           #print (f"XXX: adding {proj_abbr} to {proj_name}")
           proj_name += f" ({proj_abbr})" # add proj_abbr to end of proj_name if not already there

        role = item.get("role", "")
        if role == None:
            role = ""
        # add previous 'role' to resource name
        if role != "Unknown" and role != "" and role != None:
            resource_name = item.get("resource", "") + " - " + role
        else:
            resource_name = item.get("resource", "") 

        filtered_item = {
            "addresses": item.get("addresses", ""),
            "org_name": org_name,
            "discipline": item.get("discipline", ""),
            "latitude": item.get("latitude", ""),
            "longitude": item.get("longitude", ""),
            "resource_name": resource_name,
            "project_name": proj_name,
            "scireg_id": filtered_cnt,
            "contact_email": "unknown",
            "last_updated": "unknown",
        }

        #Skip /32s that are the only host at a give site, even its its pingable; and skip all perfSONAR hosts
        skip = 0

        # might still be some perfSONAR hosts that did not get skipped above, so skip now
        if filtered_item['discipline'] == "CS.Network Testing and Monitoring" and proj_name != "Data Mobility Exhibition":  
           #print (f"Skipping perfSONAR host at address {filtered_item['addresses']}")
           skip = 1
           skip_cnt += 1

        if skip:
            #print ("  Skipping entry", address, filtered_item)
            skipped_data.append(filtered_item)
        else:
            filtered_cnt+=1
            filtered_data.append(filtered_item)

    print (f"\nProcessed {total_cnt} science registry entries, skipping {skip_cnt} /32 addresses")


    with open(output_json_file, 'w') as f:
        json.dump(filtered_data, f, indent=2)
    print (f"\nWrote {len(filtered_data)} entries to file {output_json_file} \n")

# XXX: revisit later
#    with open(skipped_json_file, 'w') as f:
#        json.dump(skipped_data, f, indent=2)
#    print (f"Wrote {len(skipped_data)} entries to file {skipped_json_file} \n")

    return (scireg_id, skip_cnt, filtered_data)

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
    parser.add_argument("-i", "--input", required=True, help="Input JSON file")
    parser.add_argument("-o", "--output", required=True, help="Output JSON file")
    parser.add_argument("-c", "--csv", required=True, help="Output CSV file")
    parser.add_argument("-p", "--ping", action="store_true", help="Check if host is pingable")
    args = parser.parse_args()

    input_file = args.input
    output_json_file = args.output
    output_csv = args.csv
    check_ping = args.ping

    #input_file = "scireg.json"
    #output_json_file = "new_scireg.json"
    skipped_json_file = "skipped_entries.json"
    output_csv = "new_scireg.csv"

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
    print("%d entries skipped. See %s" % (skip_cnt, skipped_json_file))
    print("Done.")



