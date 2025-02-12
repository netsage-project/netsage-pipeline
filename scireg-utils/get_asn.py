#!/usr/bin/env python3

# simple program to look up ASN from Org Name from CAIDA
# See: https://api.asrank.caida.org/v2/docs

# note: filenames are hardcoded below


import csv
import requests
import time

# File Paths
INPUT_FILE = "organizations.csv"
OUTPUT_FILE = "organizations_with_asn.csv"

# CAIDA AS Rank API Endpoint
API_URL = "https://api.asrank.caida.org/v2/restful/asns"

# Function to fetch ASN using CAIDA AS Rank API
def get_asn(org_name):
    print(f"\n[INFO] Querying ASN for: {org_name}")

    try:
        response = requests.get(API_URL, params={"name": org_name}, timeout=10)
        
        if response.status_code != 200:
            print(f"[WARNING] API request failed for {org_name} (Status Code: {response.status_code})")
            return "N/A"

        data = response.json()

        # Debugging: Show the raw API response (for verification)
        print(f"[DEBUG] API response for {org_name}: {data}")

        # New logic to parse ASN from the correct structure
        if "data" in data and "asns" in data["data"] and "edges" in data["data"]["asns"]:
            asn_list = data["data"]["asns"]["edges"]
            if asn_list:
                asn = asn_list[0]["node"]["asn"]
                print(f"[SUCCESS] ASN found: {asn} for {org_name}")
                return asn

        print(f"[INFO] No ASN found for {org_name}")

    except requests.exceptions.Timeout:
        print(f"[ERROR] Request timeout for {org_name}")
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Request error for {org_name}: {e}")
    except Exception as e:
        print(f"[ERROR] Unexpected error while fetching ASN for {org_name}: {e}")

    return "N/A"

# Read input CSV file
print(f"\n[INFO] Reading input file: {INPUT_FILE}")
orgs = []
try:
    with open(INPUT_FILE, newline="", encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile)
        header = next(reader)  # Read the header row
        for row in reader:
            if row:
                orgs.append(row[0])  # Assuming org_name is in the first column

    print(f"[INFO] Found {len(orgs)} organizations in CSV file.")

except FileNotFoundError:
    print(f"[ERROR] File {INPUT_FILE} not found! Please check the filename.")
    exit(1)

# Process and fetch ASN for each organization
asn_data = []
total_orgs = len(orgs)
start_time = time.time()

for index, org in enumerate(orgs):
    print(f"\n[PROCESSING] ({index+1}/{total_orgs}) Looking up ASN for: {org}")
    
    asn = get_asn(org)
    asn_data.append([org, asn])

    # Sleep to avoid rate limits (adjust if needed)
    time.sleep(1)

# Write results to new CSV file
print(f"\n[INFO] Writing results to {OUTPUT_FILE}")
try:
    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["org_name", "ASN"])
        writer.writerows(asn_data)

    print(f"[SUCCESS] ASN data saved to {OUTPUT_FILE}")

except Exception as e:
    print(f"[ERROR] Failed to write to {OUTPUT_FILE}: {e}")

# Show total execution time
elapsed_time = time.time() - start_time
print(f"\n[INFO] Processing complete in {elapsed_time:.2f} seconds.")


