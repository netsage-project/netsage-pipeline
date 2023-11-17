#!/usr/bin/env python3

# requires mmdb_writer from: https://github.com/vimt/MaxMind-DB-Writer-python/tree/master
# pip install -U git+https://github.com/VimT/MaxMind-DB-Writer-python


# convert SCINET json file to mmdb
# the only fields we care about is ip_addresses and org_name

import json
import ipaddress  # For IPv6 support
from netaddr import IPSet
from mmdb_writer import MMDBWriter
import sys

# Input JSON file
input_json_filename = "scinet.json"

# Output MMDB file
output_mmdb_filename = "scinet.mmdb"

# these are the fields we want to get from the science registry
my_dict = {
    'org_name': 'value',
    'orginization': 'value',
    'latitude': '39.739319',
    'longitude': '-104.988937',
    'city': 'Denver',
    'state': 'CO',
    'country': 'US'
}

def convert_to_mmdb(json_data, output_mmdb_filename):

    # note: our logstash config expects database_type="GeoIP2-City"
    writer = MMDBWriter(ip_version=6, ipv4_compatible=True, database_type="GeoIP2-City")

    i = 0
    for entry in json_data:
         ip_addr = entry['addresses'] # note, these return a list, so dont add brackets when passing to IPSet
         ip_addr_v6 = entry['addresses_v6']

         # note: can not combine V4 and V6 address the same IPSet, so do them separately
         print (f"creating ip_set from {ip_addr} and {ip_addr_v6}")

         if ip_addr != None:
             try:
                 #ip_set_v4 = IPSet(ip_addr)
                 ip_set_v4 = IPSet([ip_addr])
             except Exception as e:
                 print(f"Error creating ip_set_v4 from {ip_addr}: {e}")
                 sys.exit()

             my_dict['org_name'] = entry['org_name']
             my_dict['orginization'] = entry['org_name']
             my_dict['latitude'] = entry['latitude']
             my_dict['longitude'] = entry['longitude']

             try:
	        # so logstash might expect those fields?
                writer.insert_network(ip_set_v4, my_dict)
             except Exception as e:
                 print(f"Error inserting ip_set_v4: {e}")
                 sys.exit()

         if ip_addr_v6 != None:
             try:
                 #ip_set_v6 = IPSet(ip_addr_v6)
                 ip_set_v6 = IPSet([ip_addr_v6])
             except Exception as e:
                 print(f"Error creating ip_set_v6 from {ip_addr_v6}: {e}")
                 sys.exit()

             try:
                 writer.insert_network(ip_set_v6, my_dict)
             except Exception as e:
                 print(f"Error inserting ip_set_v6: {e}")
                 sys.exit()
         i+=1

    writer.to_db_file(output_mmdb_filename)
    print (f"Created file with {i} records")


if __name__ == "__main__":

    try:
        # Read JSON data from file
        print ("Loading JSON file: ", input_json_filename)
        with open(input_json_filename, 'r') as file:
            json_data = json.load(file)

        # Convert JSON data to MMDB file
        convert_to_mmdb(json_data, output_mmdb_filename)

        print(f"Conversion complete. MMDB file saved as '{output_mmdb_filename}'")

    except FileNotFoundError:
        print(f"Error: File '{input_json_filename}' not found.")
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")


