#!/usr/bin/env python3

# combines SCinet JSON files into a single file containing subnets/booth names 
# this file can be used to create a Science Registry file, or a member-list file.

import sys
import json
import copy

# input file
subnet_info_file = "connections.json"
org_info_file = "orgs.json"
networks_file = "networks.json"

# output file
output_filename = "scinet.json"

# SciReg JSON template:
# program expects an array of these:

template = {
  "addresses": [ "" ],
  "addresses_v6": [ "" ],
  "addresses_str": "",
  "asn": "14031",
  "city": "Denver",
  "country_code": "US",
  "description": "SCinet",
  "discipline": "unknown",
  "discipline_description": "unknown",
  "ip_block_id": "-1",
  "latitude": "39.739319",
  "longitude": "-104.988937",
  "org_abbr": "SCinet",
  "org_country_code": "US",
  "org_description": "unknown",
  "org_latitude": "39.739319",
  "org_longitude": "-104.988937",
  "org_name": "SCinet",
  "org_url": "https://sc23.supercomputing.org/scinet/",
  "projects": [ { } ],
  "resource": "unknown",
  "resource_abbr": "",
  "role": "SC23",
  "role_description": "worlds fastest network"
}

# Load data from File 1
with open(subnet_info_file, 'r') as file1:
    data1 = json.load(file1)

# Load data from File 2
with open(org_info_file, 'r') as file2:
    data2 = json.load(file2)

# Load data from File 3
with open(networks_file, 'r') as file3:
    data3 = json.load(file3)

# Create a list to store the resulting data
result_data = []
# Create a dictionary to store the mapping of 'id' to 'name' from File 2
id_to_name = {}

# First add the subnets from File3 (networks) 
# for this data, dont need to do lookup by ID, just use the name in the record
for entry in data3['results']:
    subnet = entry['net']
    if subnet == None:
        #print ("No subnet: skipping")
        continue
    v6net = entry['v6net']
    name = entry['name']
    # Create a copy of the template for each iteration
    scireg_entry = copy.deepcopy(template)

    scireg_entry['addresses'] = subnet
    # in case its useful later, add V6 too
    scireg_entry['addresses_v6'] = v6net
    # not sure if this is used, but include it just in case
    scireg_entry['addresses_str'] = subnet
    scireg_entry['org_name'] = name
    #print (f"subnet {subnet} is used by {name}")
    print (f"Adding entry for subnet: {scireg_entry['addresses']}, latitude: {scireg_entry['latitude']}")
    #print (scireg_entry)
    result_data.append(scireg_entry)

print (f"added {len(result_data)} records from 'networks' file")

# Iterate over items in data2 to create the mapping from ID to name
for entry in data2["results"]:
    #print (entry)
    id_to_name[entry["id"]] = entry["name"]

#print ("ID to Name Map: ",id_to_name)

# 3rd: Iterate through the 'connections' in File 1
i = 0
for entry in data1['results']:
    id = entry['id']
    #print (f"getting name for Org ID: {id}")
    org_name = id_to_name.get(id, '')
    subnet = entry['network']['net']
    #print (f"org name for Org ID: {id} is {org_name}, subnet is {subnet}")
    scireg_entry = copy.deepcopy(template)
    scireg_entry['addresses'] = subnet
    # in case its useful later, add V6 too
    scireg_entry['addresses_v6'] = entry['network']['v6net']
    # not sure if this is used, but include it just in case
    scireg_entry['addresses_str'] = subnet 
    scireg_entry['org_name'] = org_name
    #print ("adding data to result array: ", scireg_entry)
    #print (f"Adding entry for subnet: {scireg_entry['addresses']}")
    print (f"Adding entry for subnet: {scireg_entry['addresses']}, latitude: {scireg_entry['latitude']}")
    result_data.append(scireg_entry)
    i += 1

print (f"added and additional {i} records from 'connections' file")

# Save the new data to a new JSON file
with open(output_filename, 'w') as output_file:
    json.dump(result_data, output_file, indent=4)

print(f"{len(result_data)} data records have been processed and saved to file: ", output_filename)


