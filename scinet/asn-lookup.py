#!/usr/bin/env python3

import geoip2.database
import sys

def get_asn(ip_address):
    # Path to the MaxMind ASN MMDB file
    mmdb_path = './GeoLite2-ASN.mmdb'  # Replace with the actual path to your MMDB file

    # Create a reader object
    reader = geoip2.database.Reader(mmdb_path)

    try:
        # Look up the IP address
        response = reader.asn(ip_address)
        asn = response.autonomous_system_number
        organization = response.autonomous_system_organization

        print(f'IP Address: {ip_address}')
        print(f'ASN: {asn}')
        print(f'Organization: {organization}')

    except geoip2.errors.AddressNotFoundError:
        print(f'IP Address {ip_address} not found in the database.')

    finally:
        # Close the reader to free up resources
        reader.close()

if __name__ == "__main__":
    # Check if an IP address is provided as a command line argument
    if len(sys.argv) != 2:
        print("Usage: python script.py <ip_address>")
        sys.exit(1)

    # Get the IP address from the command line argument
    ip_address_to_lookup = sys.argv[1]
    get_asn(ip_address_to_lookup)

