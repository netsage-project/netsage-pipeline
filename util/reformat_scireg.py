#!/usr/bin/env python3

# read old style of Science Registry JSON, and convert to new format
# also create xls file for for adding to a Google Sheet for editing
#
# requires this package: pip install xlwt
#
# To Do: 
#   more testing

import json
import subprocess
import csv
import re

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



def filter_fields(input_file, output_json_file, skipped_json_file):
    scireg_id = 1  # give each entry a unique ID 
    skip_cnt = 0
    filtered_data = []
    skipped_data = []
    org_address_count = {}  # Dictionary to store address count for each org_name

    with open(input_file, 'r') as f:
        data = json.load(f)

    for item in data:
        org_name = item.get("org_name", "")
        org_address_count.setdefault(org_name, 0)  # Initialize count for org_name if not already present
        resources = []

        for address in item.get("addresses", []):
            is_pingable = ping_host(address)
            if address.endswith("/32"):
                print ("  host is up")
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
            org_address_count[org_name] += 1  # Increment address count for the current org_name

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
        if (address.endswith("/32") and org_address_count[org_name] <= 1):
           print ("Skipping entry with only a single /32 that is up (%s, %d addresses up)" %(org_name, org_address_count[org_name]))
           skip = 1

        if skip:
            print ("  Skipping entry", address, filtered_item)
            print ("")
            skipped_data.append(filtered_item)
            skip_cnt += 1
        else:
            #print ("adding address", address, filtered_item)
            #print ("")
            filtered_data.append(filtered_item)
            scireg_id += 1

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
                is_pingable = resource.get('is_pingable', '')
                #projects = json.dumps(resource.get('projects', ''))  # Serialize JSON object to string
                for project in resource.get('projects', []):
                    project_name = project.get('project_name', '')
                    project_abbr = project.get('project_abbr', '')
                    if project_abbr == None:
                        # Extract text between parentheses in project_name using regular expression
                        match = re.search(r'\((.*?)\)', project_name)
                        project_abbr = match.group(1) if match else ''
                        #print ("Extracting project abbr from project name: ", project_abbr)
                        project_name = re.sub(r'\(.*?\)', '', project_name)

                    writer.writerow({
                        'org_name': org_name,
                        'org_abbr': org_abbr,
                        'discipline': discipline,
                        'contact_email': contact_email,
                        'resource_address': resource_address,
                        'resource_name': resource_name.strip(),
                        'is_pingable': is_pingable,
                        'project_name': project_name.strip(),
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



