#!/usr/bin/env python3

# this script is useful for testing/debugging netsage mmdb file.

import maxminddb
import sys

#mmdb_file = "GeoLite2-City.mmdb"
mmdb_file = "scinet.mmdb"

def mmdb_lookup(ip_address):

    try:
        # Open the MaxMind DB file
        with maxminddb.open_database(mmdb_file) as mmdb:
            # Perform the lookup
            result = mmdb.get(ip_address)
            print (result)

            if result:
                # Extract organization name
                org_name = result.get('org_name')

                print(f'IP Address: {ip_address}')
                print(f'Organization Name: {org_name}')
            else:
                print(f'No information found for IP Address: {ip_address}')

    except maxminddb.errors.InvalidDatabaseError as e:
        print(f'Error opening MaxMind DB: {e}')

if __name__ == "__main__":
    # Check if an IP address is provided as a command-line argument
    if len(sys.argv) != 2:
        print('Usage: python mmdb_lookup.py <IP_ADDRESS>')
    else:
        ip_address = sys.argv[1]
        mmdb_lookup(ip_address)

