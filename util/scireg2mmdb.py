#!/usr/bin/env python3

# This program reformats scireg.json to the format needed to use 
# this docker image: https://hub.docker.com/r/cameronkerrnz/json-to-mmdb
# which runs this script: https://github.com/cameronkerrnz/json-to-mmdb/blob/master/app/json-to-mmdb
# json-to-mmdb runs in docker to simplify all the dependancies,
# Note that this warning is expected, and can be ignored for now:
#      MaxMind::DB::Writer::Tree is deprecated and should no longer be used 
# If that perl modules goes away, here is a possible replacement: https://github.com/maxmind/mmdbwriter
#
# TODO: add support for IPv6

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
    outfile = None
    num_entries=0
    skipped_entries=0

    # Parse command line arguments
    try:
        opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
    except getopt.GetoptError:
        print(f'Usage: {os.path.basename(__file__)} -i <inputfile> -o <outputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print(f'Usage: {os.path.basename(__file__)} -i <inputfile> -o <outputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            infile = arg
        elif opt in ("-o", "--ofile"):
            outfile = arg

    # Check if both input and output files are provided
    if infile is None or outfile is None:
        print(f'Usage: {os.path.basename(__file__)} -i <inputfile> -o <outputfile>')
        sys.exit(2)

    # Read and parse the input JSON file
    with open(infile, "r") as file:
        data = json.load(file)

    # Initialize list to hold allocations
    allocations = []

    # Iterate over each item in the data
    for item in data:
        # Iterate over each resource in the item
        for resource in item.get("resources", []):
            # Check if the resource has 'address' and 'is_pingable' keys
            if "address" in resource and "is_pingable" in resource:
            #if "address" in resource and "is_pingable" in resource:  # to skip entries not pingable..
                # Check if the subnet is IPv6, if so, skip
                if not check_subnet(resource["address"]):
                    print (f"  Skipping resource: {resource["resource_name"]} \n")
                    skipped_entries += 1
                    continue

                # Construct allocation for each resource
                allocation = {
                    "subnet": resource["address"],
                    "discipline": item["discipline"],
                    "latitude": item["latitude"],
                    "longitude": item["longitude"],
                    "org_name": item["org_name"],
                    "org_abbr": item["org_abbr"],
                    "resource_name": resource["resource_name"],
                    "projects": str(resource.get("projects", ""))
                }
                allocations.append(allocation)
                num_entries += 1

    # Construct the final JSON object
    final_json = {
        "schema": {
            "database_type": "network",
            "description": {"en": "NetSage Science Registry Data"},
            "ip_version": 4,
            "types": {
                "org_name": "utf8_string",
                "org_abbr": "utf8_string",
                "discipline": "utf8_string",
                "latitude": "utf8_string",
                "longitude": "utf8_string",
                "subnet": "utf8_string",
                "resource_name": "utf8_string",
                "projects": "utf8_string"
            }
        },
        "allocations": allocations
    }

    print(f"Created {num_entries} and skipped {skipped_entries} entries in the DB")
    # Temporary file
    tmpfile = "temp.json"

    # Write final JSON object to temporary JSON file
    with open(tmpfile, "w") as file:
        json.dump(final_json, file, indent=2)

    print ("Converting file %s to mmdb using docker " % outfile)
    print (f"Running: docker run -v {os.getcwd()}:/data/ --rm cameronkerrnz/json-to-mmdb:latest --input=/data/{tmpfile} --output=/data/{outfile}")

    # Run the Docker container to convert JSON to mmdb
    subprocess.run(["docker", "run", "-v", f"{os.getcwd()}:/data/", "--rm", "cameronkerrnz/json-to-mmdb:latest", f"--input=/data/{tmpfile}", f"--output=/data/{outfile}"])

    print("Done. Results in file: ", outfile)

if __name__ == "__main__":
    main(sys.argv[1:])


