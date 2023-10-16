#!/usr/bin/env python3

# NetSage pipeline uses a MMDB to map IP address to City name, lat, and long
# should be able to look up any host in the subnet
#
# this program is mainly used for testing/debugging

# note: most everything is shoved in 'city' as a bit JSON blob
# 

import argparse
import json
import geoip2.database

# for testing
# LHC/Atlas host
#ip_address = "192.170.224.100"
# TACC perfsonar host
#ip_address = "129.114.0.202"

def mmdb_lookup(ip_address, mmdb_file_path):
    reader = geoip2.database.Reader(mmdb_file_path)
    try:
        response = reader.city(ip_address)
        # the mmdb file that Lisa generated shoves everything into 'city name'. 
        city = response.city.name
        #print (response.city)
        latitude = response.location.latitude
        longitude = response.location.longitude

        # convert JSON string to dict
        jdata = json.loads(city)
        # extract data from JSON
        country = jdata['country_code']
        org_name = jdata['org_name']
        org_abbr = jdata['org_abbr']
        discipline = jdata['discipline']
        resource = jdata['resource']
        # projects is a array, that includes project_name
        projects = jdata['projects']
        # XXX: Fixme: need to handle case with multiple project names
        try:
            project_name = projects[0]['project_name']
        except:
            project_name = ""
        asn = jdata['asn']

        print(f"IP: {ip_address}")
        print(f"Country: {country}")
        #print(f"City: {city}")
        print(f"Organization: {org_name}, {org_abbr}")
        print(f"Latitude: {latitude}")
        print(f"Longitude: {longitude}")
        print(f"ASN: {asn}")
        print(f"discipline: {discipline}")
        print(f"resource: {resource}")
        print(f"project name: {project_name}")

    except geoip2.errors.AddressNotFoundError:
        print("IP address not found in the MMDB.")

    finally:
        reader.close()

# Create the command line argument parser
parser = argparse.ArgumentParser(description='mmdb Lookup by IP Address')
parser.add_argument('-i', '--ip_address', type=str, nargs='?', default='8.8.8.8', help='IP address')
parser.add_argument('-f', '--filename', type=str, nargs='?', default='scireg.mmdb', help='mmdb file (default=scireg.mmdb)')


# Parse the command line arguments
args = parser.parse_args()
ip_address = args.ip_address
mmdb_file_path = args.filename

# Perform MMDB lookup
mmdb_lookup(ip_address, mmdb_file_path)


