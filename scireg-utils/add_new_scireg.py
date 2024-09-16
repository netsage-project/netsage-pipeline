#!/usr/bin/env python3

# adds new Science Registry Entry to existing file from a '.template' file.
#
#Usage: python combine_json.py [input_file1] [input_file2] [output_file]
#    Default input_file1: scireg.json
#    Default input_file2: scireg.template.json
#    Default output_file: newScireg.json

# note: scireg.template.json must contain only 1 entry.
#   If adding multiple entries, run this multiple times

# note: this will also re-number the scireg_id field

import json
import sys
from datetime import datetime

def renumber_scireg_id(data):
    """Renumber 'scireg_id' field sequentially starting from 0."""
    for i, entry in enumerate(data):
        entry['scireg_id'] = i
    return data

def update_last_updated(data):
    """Update the 'last_updated' field in all entries with today's date."""
    today = datetime.today().strftime('%Y-%m-%d')
    print ("Setting last_updated field to: ", today)
    #print ("data: ", data)
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
        print ("Adding to Science Registry: ", data2)

        # add data2 to the end of data1
        data1.append(data2)

        # Renumber scireg_id
        renumbered_data = renumber_scireg_id(data1)

        # Write the combined and renumbered data to a new file
        with open(output_file, 'w') as f_out:
            json.dump(renumbered_data, f_out, indent=4)

if __name__ == "__main__":
    # Default filenames
    default_file1 = 'scireg.json'
    default_file2 = 'scireg.template.json'
    default_output_file = 'newScireg.json'

   # Check for the help flag
    if '-h' in sys.argv:
        print(f"Usage: combine_json.py [input_file1] [input_file2] [output_file]")
        print(f"    Default input_file1: {default_file1}")
        print(f"    Default input_file2: {default_file2}")
        print(f"    Default output_file: {default_output_file}")
        sys.exit(0)

   # Set file names or fallback to defaults if not provided
    file1 = sys.argv[1] if len(sys.argv) > 1 else default_file1
    file2 = sys.argv[2] if len(sys.argv) > 2 else default_file2
    output_file = sys.argv[3] if len(sys.argv) > 3 else default_output_file

    combine_json_files(file1, file2, output_file)
    print(f"Combined JSON data written to {output_file}")


