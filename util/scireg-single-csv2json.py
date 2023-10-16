#!/usr/bin/env python3

# Convert a single CSV entry to JSON, and add it to the existing scireg.json file
#   for use by the script resourcedb-make-mmdb.pl
#
# The input CSV comes from from Lisa's input form:  
#     https://docs.google.com/spreadsheets/d/1mQNmj6XgfR7g4gLPcdGtiUzIhkTpM3Y4_eM49rNeUOk/edit?usp=sharing
#
# scireg-single-csv2json.py -h
# usage: scireg-single-csv2json.py [-h] [-c CSV_FILE] [-j JSON_FILE] [-o OUTPUT_FILE]
# 
# Add Science Registry Entry from CSV
# 
# optional arguments:
#   -h, --help            show this help message and exit
#   -c CSV_FILE, --csv_file CSV_FILE
#                         CSV input file
#   -j JSON_FILE, --json_file JSON_FILE
#                         Current JSON file
#   -o OUTPUT_FILE, --output_file OUTPUT_FILE
#                         New JSON file


# the JSON file to be added to is here:
#     - http://epoc-rabbitmq.tacc.utexas.edu/NetSage/scireg.json
#
# After running this script, then run this: 
#   - perl resourcedb-make-mmdb.pl -i scireg-updated.json -o scireg.mmdb


# Column names must be:
#Notes (additional info) ,IP addresses of source and destination hosts (required),ASN (required),"Organization (required) ","Sub- Organization ","Sub- Organization Abbreviation","Resource Name (required)",shorter Resource name ,Science Discipline of data sent to/from the hosts (required),Description of the hosts/sub-organization ,URL of the resource or a webpage with info about the sub-organization or resource ,"Geolocation (lat, long of hosts in the IP list) ",Country (of the hosts) ,Role(s) the hosts play ,Project Name (if any)

# note: Be sure the CSV export from Google Docs keeps all the column names in 1 row

# Warning: This script is fragile. Might require minor tweeks depending on input CSV file

# Possible issues in the future:
#   old method maps Country name to a country 'code' (2 letter abbreviation), but this version just uses the country name.
#   old method fills in a ip_block_id from a table of ip_blocks. This version just sets to 0, as I dont think its used.
#

import csv
import json
import argparse


def read_csv_file(file_path):
    data = []
    with open(file_path, 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            # Remove quote marks from field values, as they break stuff
            data.append(row)
            #print ("input row: ",row)
    return data


def generate_json_objects(data):
    json_objects = []
    for row in data:
        json_object = {}
        
        # Populate IP block details
        json_object["addresses"] = [address.strip() for address in row["IP addresses of source and destination hosts (required)"].split(",")]
        json_object["addresses_str"] = row["IP addresses of source and destination hosts (required)"]
        json_object["asn"] = row["ASN (required)"]
        json_object["country_code"] = row[next(key for key in row.keys() if key.startswith("Country"))]
        json_object["description"] = row[next(key for key in row.keys() if key.startswith("Description"))]
        json_object["discipline"] = row["Science Discipline of data sent to/from the hosts (required)"]
        json_object["discipline_description"] = row[next(key for key in row.keys() if key.startswith("Role"))] 
        json_object["ip_block_id"] = 0   # XXX: pretty sure this is not required, and not sure how to find it if it is
        json_object["latitude"], json_object["longitude"] = [coord.strip() for coord in row["Geolocation (lat, long of hosts in the IP list) "].split(",")]
        
        # Populate organization details
        json_object["org_abbr"] = row["Sub- Organization Abbreviation"]
        json_object["org_description"] = row["Sub- Organization "]

        json_object["org_country_code"] = json_object["country_code"]   # Same as above
        json_object["org_latitude"] = json_object["latitude"] # same as above
        json_object["org_longitude"] = json_object["longitude"]

        json_object["org_name"] = row[next(key for key in row.keys() if key.startswith("Organization"))]
        json_object["org_url"] = row[next(key for key in row.keys() if key.startswith("URL"))]
        
        # Populate project details
        project_name = row[next(key for key in row.keys() if key.startswith("Project"))]
        project_abbr = row[next(key for key in row.keys() if key.startswith("shorter"))]
        if project_name:
            project = {
                "project_abbr": project_abbr,
                "project_contact": "",
                "project_description": "",
                "project_email": "",
                "project_name": project_name,
                "project_url": ""
            }
            json_object["projects"] = [project]
        else:
            json_object["projects"] = []

        json_object["resource"] = row[next(key for key in row.keys() if key.startswith("Resource"))]
        json_object["resource_abbr"] = row["shorter Resource name "]
        json_object["role"] = row[next(key for key in row.keys() if key.startswith("Role"))]

        #print (json_object)
        
        # Add the JSON object to the array
        json_objects.append(json_object)
    
    return json_objects

# Create the command line argument parser
parser = argparse.ArgumentParser(description='Add Science Registry Entry from CSV')
parser.add_argument('-c', '--csv_file', type=str, default='new_org.csv', help='CSV input file')
parser.add_argument('-j', '--json_file', type=str, default='scireg.json', help='Current JSON file')
parser.add_argument('-o', '--output_file', type=str,  default='scireg-updated.json', help='New JSON file')

# Parse the command line arguments
args = parser.parse_args()
csv_file = args.csv_file
json_file = args.json_file
output_file = args.output_file


# Read data from CSV
data = read_csv_file(csv_file)

# Generate JSON object from CSV
json_object = generate_json_objects(data)

# Read the existing JSON file
print ("Loading file: ", json_file)
with open(json_file, 'r') as file2:
    scireg = json.load(file2)

# Combine the 2 JSON objects
scireg.extend(json_object)

print ("Saving results to file: ", output_file)

# Write the merged data to the output file
with open(output_file, 'w') as outfile:
    json.dump(scireg, outfile, indent=4)



