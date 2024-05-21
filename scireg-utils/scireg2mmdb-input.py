#!/usr/bin/env python3

# This program reformats scireg.json to the format needed by program scireg2mmdb.go 
#
# TODO: test support for IPv6

import json
import subprocess
import os
import sys
import getopt
import ipaddress  

def check_subnet(subnet):
    try:
        ipaddress.ip_network(subnet)
        if ':' in subnet:  # Check if IPv6
            print("Warning: IPv6 address detected. IPv6 is not yet supported.", subnet)
            return False
        else:
            return True
    except ValueError:
        print("Invalid subnet address.", subnet)
        return False

def main(argv):
    # Default values
    infile = None
    num_entries=0
    skipped_entries=0

    # Parse command line arguments
    try:
        opts, args = getopt.getopt(argv,"hi:",["ifile=","ofile="])
    except getopt.GetoptError:
        print(f'Usage: {os.path.basename(__file__)} -i <inputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print(f'Usage: {os.path.basename(__file__)} -i <inputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            infile = arg

    # Check if both input and output files are provided
    if infile is None :
        print(f'Usage: {os.path.basename(__file__)} -i <inputfile>')
        sys.exit(2)

    # Read and parse the input JSON file
    with open(infile, "r") as file:
        data = json.load(file)

    print (f"Input file contains {len(data)} entries")

    # Initialize list to hold allocations
    resources = []

    # Iterate over each item in the data
    for item in data:
        # Iterate over each resource in the item
        if 'description' in item:
             print("Error: old style science registry file. Need to use updated file. ")
             sys.exit()
        for resource in item.get("resources", []):
            # Check if the resource has 'address' and 'is_pingable' keys
            if "address" in resource:
            #if "address" in resource and "is_pingable" in resource:  # to skip entries not pingable..
                # Check if the subnet is IPv6, if so, skip
                #if not check_subnet(resource["address"]):
                #    print(f"  Skipping resource: {resource['resource_name']} \n")
                #    skipped_entries += 1
                #    continue
                #print (resource)
                # to just print warning about V6
                #check_subnet(resource["address"])

                # Construct allocation for each resource
                resource = {
                    "subnet": resource["address"],
                    "discipline": item["discipline"],
                    "latitude": item["latitude"],
                    "longitude": item["longitude"],
                    "org_name": item["org_name"],
                    "org_abbr": item["org_abbr"],
                    "resource_name": resource["resource_name"],
                    "projects": str(resource.get("projects", ""))
                }
                #print ("Adding: ", resource)
                resources.append(resource)
                num_entries += 1

    #print(f"Length of resources array: {len(resources)}")

    # Construct the final JSON object
    final_json = {
        "resources": resources
    }

    print(f"Created {num_entries} and skipped {skipped_entries} entries in the DB")

    tmpfile = "scireg-temp.json"

    # Write final JSON object to temporary JSON file
    with open(tmpfile, "w") as file:
        json.dump(final_json, file, indent=2)

    print("Done. Results in file: ", tmpfile)
    print(f"Now run: scireg2mmdb -i {tmpfile} -o scireg-new.mmdb ")

if __name__ == "__main__":
    main(sys.argv[1:])


