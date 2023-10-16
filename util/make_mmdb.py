#!/usr/bin/env python3

# this code is a chatGPT conversion of the program resourcedb-make-mmdb.pl
# it is not yet tested

import json
import os
import sys
import getopt
# pip3 install maxminddb
from maxminddb import open_database
from maxminddb.const import MODE_AUTO
# pip3 install netaddr
from netaddr import IPNetwork, IPAddress

# command line params are input and output file names
scireg_json_file = '/usr/share/resourcedb/www/exported/scireg.json'
outfile = '/usr/share/resourcedb/www/exported/scireg.mmdb'
help = False

opts, _ = getopt.getopt(sys.argv[1:], "i:o:h", ["input=", "output=", "help"])
for opt, arg in opts:
    if opt in ("-i", "--input"):
        scireg_json_file = arg
    elif opt in ("-o", "--output"):
        outfile = arg
    elif opt in ("-h", "--help"):
        help = True

if help:
    print("USAGE: python make_mmdb.py [-i <scireg.json file> -o <scireg.mmdb file>]")
    sys.exit()

if not os.path.exists(scireg_json_file):
    print(f"ERROR: json file {scireg_json_file} does not exist")
    sys.exit()

# Load the Science Registry JSON data
with open(scireg_json_file, 'r') as file:
    scireg_json = file.read()

scireg = json.loads(scireg_json)

# Convert JSON data to dictionaries with keys = single CIDRs and values = resource info
ipv4_singles = {}
ipv6_singles = {}
for res in scireg:
    # Make a copy of the dictionary, remove unnecessary fields, and extract latitude and longitude
    data = res.copy()
    del data['addresses_str']
    del data['addresses']
    del data['ip_block_id']
    lat = data['latitude']
    lon = data['longitude']
    data_json = json.dumps(data)

    # For each CIDR block/address in this resource, save the JSON in the "city name" GeoIP field
    # (another logstash filter will break it up later)
    # Latitude and longitude are required for the logstash geoip filter to return a match
    for addr in res['addresses']:
        if ':' in addr:
            ipv6_singles[addr] = {
                'city': {'names': {'en': data_json}},
                'location': {'latitude': lat, 'longitude': lon}
            }
        else:
            ipv4_singles[addr] = {
                'city': {'names': {'en': data_json}},
                'location': {'latitude': lat, 'longitude': lon}
            }

# Add singles to the fake GeoIP database in the right order, with the most precise/longest prefix addresses last
# (This is required since the logstash geoip filter returns the last match)
sorted_ipv4_singles = sorted(ipv4_singles.items(), key=lambda x: IPNetwork(x[0]), reverse=True)
sorted_ipv6_singles = sorted(ipv6_singles.items(), key=lambda x: IPNetwork(x[0]), reverse=True)

# Create the MaxMind DB writer
with open(outfile, 'wb') as file:
    writer = open_database(file, mode=MODE_AUTO)

    # Insert IPv4 addresses
    for address, data in sorted_ipv4_singles:
        network = IPNetwork(address)
        writer.insert_network(network, data)

    # Insert IPv6 addresses
    for address, data in sorted_ipv6_singles:
        network = IPNetwork(address)
        writer.insert_network(network, data)

    writer.close()

# Check the file size
if os.path.getsize(outfile) > 3000:
    print(f"{outfile} has been created")
    # On success, write status file for monitoring
else:
    print(f"{outfile} seems to be too small. Check to be sure it is ok.")


def byprefix(address):
    # This is a sort function for IPs in CIDR notation.
    # Sort first by prefix (the /xx).
    # If /xx's of a and b are the same, convert to IPAddress objects and compare the IP parts as integers.
    # (Use netaddr.IPAddress and int() method so this works for both IPv4 and IPv6)
    def sort_key(addr):
        prefix_len = int(addr.split('/')[-1])
        ip = IPAddress(addr.split('/')[0])
        return (prefix_len, int(ip))

    return sorted(address, key=sort_key)


