#!/usr/bin/env python3

# read old style of Science Registry JSON, and convert to new format
# also create csv file for for adding to a Google Sheet for editing
#

import json
import subprocess
import csv
import re
import ipaddress

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


def filter_fields(input_file, output_json_file, skipped_json_file):
    scireg_id = 1  # give each entry a unique ID 
    skip_cnt = 0
    filtered_data = []
    skipped_data = []
    subnet_address_count = {}  # Dictionary to store address count for each subnet (x.x.x.0)

    with open(input_file, 'r') as f:
        data = json.load(f)

    for item in data:
        org_name = item.get("org_name", "")
        resources = []

        for address in item.get("addresses", []):
            is_pingable = ping_host(address)
            if address.endswith("/32"):
                print ("  host is up")
            subnet = extract_ip_subnet(address)
            #print("  subnet: ", subnet)
            subnet_address_count.setdefault(subnet, 0)  # Initialize count for subnet if not already present
            projects = []  # Initialize the projects array for each address
            for project in item.get("projects", []):
                projects.append({
                    "project_abbr": project.get("project_abbr", ""),
                    "project_name": project.get("project_name", "")
                })
            resources.append({
                "address": address,
                "resource_name": item.get("resource", ""),
                "is_pingable": is_pingable,
                "projects": projects
            })
            subnet_address_count[subnet] += 1  # Increment address count for the current subnet

        filtered_item = {
            "org_name": item.get("org_name", ""),
            "org_abbr": item.get("org_abbr", ""),
            "discipline": item.get("discipline", ""),
            "latitude": item.get("latitude", ""),
            "longitude": item.get("longitude", ""),
            "scireg_id": scireg_id,
            "contact_email": "unknown",
            "last_update_date": "",
            "resources": resources
        }
        #Skip /32s that are the only host at a give site, even its its pingable; and skip all perfSONAR hosts
        skip = 0
        if filtered_item['discipline'] == "CS.Network Testing and Monitoring":  
           print ("Skipping perfSONAR host")
           skip = 1
        if (address.endswith("/32") and subnet_address_count[subnet] <= 1):
           print ("Skipping entry %s, only a single /32 that is up on subnet %s (%d addresses up)" %(org_name, subnet, subnet_address_count[subnet]))
           skip = 1

        if skip:
            print ("  Skipping entry", address, filtered_item)
            print ("")
            skipped_data.append(filtered_item)
            skip_cnt += 1
        else:
            if subnet_address_count[subnet] > 1:
                print ("Org: %s; Found %d addresses on subnet %s" %(org_name, subnet_address_count[subnet], subnet))
            #print ("adding address", address, filtered_item)
            #print ("")
            filtered_data.append(filtered_item)
            scireg_id += 1

    # Sort the filtered_data by discipline
    filtered_data.sort(key=lambda x: x["discipline"])

    with open(output_json_file, 'w') as f:
        json.dump(filtered_data, f, indent=2)

    with open(skipped_json_file, 'w') as f:
        json.dump(skipped_data, f, indent=2)

    return (scireg_id, skip_cnt, filtered_data)

# Function to write data to CSV
def write_to_csv(data, output_csv):
    with open(output_csv, 'w', newline='') as csvfile:
        fieldnames = ['org_name', 'org_abbr', 'discipline', 'contact_email', 'resource_address', 'resource_name', 'is_pingable', 'project_name', 'project_abbr']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()

        for entry in data:
            org_name = entry.get('org_name', '')
            org_abbr = entry.get('org_abbr', '')
            discipline = entry.get('discipline', '')
            contact_email = entry.get('contact_email', '')
            for resource in entry.get('resources', []):
                resource_address = resource.get('address', '')
                resource_name = resource.get('resource_name', '')
                if resource_name:
                     resource_name = resource_name.strip()
                is_pingable = resource.get('is_pingable', '')
                #projects = json.dumps(resource.get('projects', ''))  # Serialize JSON object to string
                for project in resource.get('projects', []):
                    project_name = project.get('project_name', '')
                    project_abbr = project.get('project_abbr', '')
                    if project_abbr == None:
                        if project_name:
                            # Extract text between parentheses in project_name using regular expression
                            match = re.search(r'\((.*?)\)', project_name)
                            project_abbr = match.group(1) if match else ''
                            #print ("Extracting project abbr from project name: ", project_abbr)
                            project_name = re.sub(r'\(.*?\)', '', project_name)
                            if project_name:
                                project_name = project_name.strip()

                    writer.writerow({
                        'org_name': org_name,
                        'org_abbr': org_abbr,
                        'discipline': discipline,
                        'contact_email': contact_email,
                        'resource_address': resource_address,
                        'resource_name': resource_name(),
                        'is_pingable': is_pingable,
                        'project_name': project_name,
                        'project_abbr': project_abbr
                })



if __name__ == "__main__":
    input_file = "scireg.json"
    output_json_file = "new_scireg.json"
    skipped_json_file = "skipped_entries.json"
    output_csv = "new_scireg.csv"

    cnt,skip_cnt,data = filter_fields(input_file, output_json_file,skipped_json_file)

    # Write data to CSV
    write_to_csv(data, output_csv)

    total_32s = ping_succeeded + ping_failed
    print("\nFound %d valid subnet entries, including %d /32s, %d are pingable, %d are not" % (cnt, total_32s, ping_succeeded, ping_failed))
    print("Results written to files: JSON - %s, CSV - %s" % (output_json_file, output_csv))
    print("%d entries skipped. See %s" % (skip_cnt, skipped_json_file))
    print("Done.")



