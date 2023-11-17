#!/usr/bin/env python3

input_file = "scinet.json"
output_file = "scinet-members-list.rb"

import json

# Read the JSON file
with open(input_file, 'r') as file:
    data = json.load(file)

reformatted_data = {}
for entry in data:
    key = f'"{entry["addresses"]}"'
    value = f'"{entry["org_name"]}"'
    if key != None:
       reformatted_data[key] = value
    key6 = f'"{entry["addresses_v6"]} "'
    if key6 != None:
       reformatted_data[key6] = value


# Write the reformatted data to a new file
with open(output_file, 'w') as file:
    file.write("@asn_list['scinet']  = [14031] \n\n")
    file.write("@members['scinet'] = {\n")
    for key, value in reformatted_data.items():
        file.write(f'    {key} => {value},\n')
    file.write("}\n")

print ("results writen to file: ", output_file)


