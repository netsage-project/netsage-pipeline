#!/usr/bin/env python3

# adds new Science Registry Entry to existing file from a '.template' file.
# Usage:
# add new entry:
#   add_new_scireg.py -i input_file1.json -t input_file2.json -o output_file.json
# cleanup
#   add_new_scireg.py --clean -i input_file1.json -o output_file.json

# note: scireg.template.json must contain only 1 entry.
#   If adding multiple entries, run this multiple times

# note: this will also re-number the scireg_id field

import json
import sys
from datetime import datetime
import argparse

def sort_by_org_name(data):
    """Sort entries by 'org_name' field."""
    return sorted(data, key=lambda x: x.get('org_name', '').lower())

def renumber_scireg_id(data):
    """Renumber 'scireg_id' field sequentially starting from 0."""
    for i, entry in enumerate(data):
        entry['scireg_id'] = i
    return data

def update_last_updated(data):
    """Update the 'last_updated' field in all entries with today's date."""
    today = datetime.today().strftime('%Y-%m-%d')
    print ("Setting last_updated field to: ", today)
    data['last_updated'] = today
    return data

def remove_comments(file_content):
    """Remove lines starting with // from a JSON-like string."""
    cleaned_content = []
    for line in file_content:
        if not line.strip().startswith("//"):
            cleaned_content.append(line)
    return ''.join(cleaned_content)

def combine_json_files(file1, file2, output_file):
    """Combine two JSON files, renumber 'scireg_id', and update 'last_updated' for the second file."""
    with open(file1, 'r') as f1, open(file2, 'r') as f2:
        data1 = json.load(f1)

        # Read and clean the second file
        file2_content = f2.readlines()
        cleaned_file2_content = remove_comments(file2_content)

        # Load the cleaned content into JSON
        data2 = json.loads(cleaned_file2_content)

        # Update 'last_updated' field for the second file
        data2 = update_last_updated(data2)
        print("Adding to Science Registry: ", data2)

        # add data2 to the end of data1
        data1.append(data2)

        data = sort_by_org_name(data1)

        # Renumber scireg_id
        renumbered_data = renumber_scireg_id(data)

        # Write the combined and renumbered data to a new file
        with open(output_file, 'w') as f_out:
            json.dump(renumbered_data, f_out, indent=4)

def clean_and_renumber(file1, output_file):
    """Load JSON, sort by org_name, and renumber scireg_id without merging."""
    with open(file1, 'r') as f1:
        data = json.load(f1)

        data = sort_by_org_name(data)

        # Remove duplicates based on 'org_name' and 'addresses'
        seen_entries = {}
        unique_data = []
        for entry in data:
            org_name = entry.get('org_name', '').strip()
            addresses = tuple(entry.get('addresses', []))  # Convert addresses to a tuple for hashability
            identifier = (org_name, addresses)

            if identifier in seen_entries:
                print(
                    f"Duplicate entry removed: scireg_id={entry.get('scireg_id')}, "
                    f"matches scireg_id={seen_entries[identifier]}, "
                    f"org_name='{org_name}', addresses={addresses}"
                )
            else:
                seen_entries[identifier] = entry.get('scireg_id')
                unique_data.append(entry)

        renumbered_data = renumber_scireg_id(data)

        with open(output_file, 'w') as f_out:
            json.dump(renumbered_data, f_out, indent=4)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Combine and clean Science Registry JSON files.")
    parser.add_argument('--clean', action='store_true', help="Sort by org_name and renumber scireg_id without merging files.")
    parser.add_argument('-i', '--input_file1', default='scireg.json', help="Input file 1 (default: scireg.json)")
    parser.add_argument('-t', '--input_file2', default='scireg.template.json', help="Input file 2 (default: scireg.template.json)")
    parser.add_argument('-o', '--output_file', default='newScireg.json', help="Output file (default: newScireg.json)")

    args = parser.parse_args()

    if args.clean:
        # Clean and renumber without merging
        clean_and_renumber(args.input_file1, args.output_file)
        print(f"Cleaned and renumbered data written to {args.output_file}")
    else:
        # Combine and process files
        combine_json_files(args.input_file1, args.input_file2, args.output_file)
        print(f"Combined JSON data written to {args.output_file}")


