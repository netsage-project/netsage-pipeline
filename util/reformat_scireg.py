#!/usr/bin/env python3

# read old style of Science Registry JSON, and convert to new format
# also create xls file for Jin

import json
import subprocess
import xlwt

ping_suceeded = 0
ping_failed = 0

def ping_host(address):
    global ping_suceeded
    global ping_failed
    
    if address.endswith("/32"):
        ip = address.split("/")[0]
        print("pinging host:", ip)
        try:
            subprocess.run(["ping", "-c", "1", '-W', '1', ip], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            ping_suceeded += 1
            return 1  # Ping succeeded
        except subprocess.CalledProcessError:
            print("ping failed.")
            ping_failed += 1
            return 0  # Ping failed
    else:
        return 2  # For non /32 addresses, set is_pingable to 2

def filter_fields(input_file, output_json_file, output_xls_file):
    workbook = xlwt.Workbook()
    sheet = workbook.add_sheet("Data")

    # Column headers for XLS file
    headers = ["org_name", "org_abbr", "address", "resource_name", "is_pingable"]
    for col, header in enumerate(headers):
        sheet.write(0, col, header)

    row = 1  # Start writing data from the second row
    filtered_data = []

    with open(input_file, 'r') as f:
        data = json.load(f)

    for item in data:
        resources = []
        for address in item.get("addresses", []):
            is_pingable = ping_host(address)
            resources.append({
                "address": address,
                "resource_name": item.get("resource", ""),
                "is_pingable": is_pingable
            })
            sheet.write(row, 0, item.get("org_name", ""))
            sheet.write(row, 1, item.get("org_abbr", ""))
            sheet.write(row, 2, address)
            sheet.write(row, 3, item.get("resource", ""))
            sheet.write(row, 4, is_pingable)
            row += 1

        filtered_item = {
            "org_name": item.get("org_name", ""),
            "org_abbr": item.get("org_abbr", ""),
            "discipline": item.get("discipline", ""),
            "latitude": item.get("latitude", ""),
            "longitude": item.get("longitude", ""),
            "resources": resources
        }
        filtered_data.append(filtered_item)

    with open(output_json_file, 'w') as f:
        json.dump(filtered_data, f, indent=2)

    workbook.save(output_xls_file)

    total_32s = ping_suceeded + ping_failed
    print("Found %d /32s, %d are pingable, %d are not" % (total_32s, ping_suceeded, ping_failed))
    print("Results written to files: JSON - %s, XLS - %s" % (output_json_file, output_xls_file))
    print("Done.")

if __name__ == "__main__":
    input_file = "scireg.json"
    output_json_file = "new_scireg.json"
    output_xls_file = "new_scireg.xls"

    filter_fields(input_file, output_json_file, output_xls_file)


