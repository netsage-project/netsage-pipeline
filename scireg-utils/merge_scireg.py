#!/usr/bin/env python3

# Simple program to merge unique Science Registry files from 2 JSON files, ignoring scireg_id
#
# sample use: 
#  merge_scireg.py newScireg.json newScireg-testing.json merged.json
#
# after running this, use add_new_scireg.py --clean to fix scireg_ids
#  add_new_scireg.py --clean -i merged.json -o clean.json

import json
import argparse

def normalize(obj):
    """Remove the `scireg_id` field from a JSON object."""
    obj_copy = obj.copy()
    obj_copy.pop('scireg_id', None)
    obj_copy.pop('community', None)  # Exclude 'community' from normalization
    return obj_copy

def merge_json_files(file1, file2, output_file):
    # Load JSON files
    with open(file1, 'r') as f1, open(file2, 'r') as f2:
        data1 = json.load(f1)
        data2 = json.load(f2)

    # Deduplicate objects while ignoring `scireg_id` and handling `community`
    seen = {}
    merged = []

    for obj in data1 + data2:
        normalized = json.dumps(normalize(obj), sort_keys=True)  # Serialize for deduplication
        if normalized in seen:
            # If already seen and the current object has 'community', replace the existing one
            if 'community' in obj and (not 'community' in seen[normalized] or not seen[normalized]['community']):
                merged.remove(seen[normalized])
                merged.append(obj)
                seen[normalized] = obj
        else:
            seen[normalized] = obj
            merged.append(obj)

    # Save merged results to the output file
    with open(output_file, 'w') as out:
        json.dump(merged, out, indent=4)

    # Print statistics
    print(f"Number of objects in '{file1}': {len(data1)}")
    print(f"Number of objects in '{file2}': {len(data2)}")
    print(f"Number of unique objects in merged file: {len(merged)}")
    print(f"Merged JSON written to '{output_file}'.")

if __name__ == "__main__":
    # Set up command-line arguments
    parser = argparse.ArgumentParser(description="Merge two JSON files, removing duplicates based on all fields except 'scireg_id'.")
    parser.add_argument("infile1", help="Path to the first input JSON file.")
    parser.add_argument("infile2", help="Path to the second input JSON file.")
    parser.add_argument("output_file", help="Path to the output JSON file.")

    args = parser.parse_args()

    # Call the merge function with provided arguments
    merge_json_files(args.infile1, args.infile2, args.output_file)

