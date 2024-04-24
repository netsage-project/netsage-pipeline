#!/usr/bin/env python3

# read Rucio FTS logs and convert them into a JSON format that can be feed to the NetSage pipeline.
# by default all IPs are de-identified

# NetSage pipeline wants somthing that looks like netflow.
# e.g. something like this:
#{"@timestamp": "2024-04-09T03:34:33.430", 
# "meta": {"flow_type": "fts", "src_port": 443, "dst_port": 50001, "sensor_id": "fts.server.name", "src_ip": "129.114.63.105",
# "protocol": "tcp", "num_files": 12, "dst_ip": "68.40.207.95", "src_asn": 0, "dst_asn": 0}, 
# "values": {"num_packets": 217360, "num_bits": 2608321768, "duration": 21.265625, "packets_per_second": 10221.19,
# "bits_per_second": 122654366.754}, "type": "fts", "start": 1712651652.164, "end": 1712651673.43}


# Assumptions:
# protocol": "tcp", might there be others?
# num_packets = total_file_size / 1500  ; this wrong for jumbo frames, but num_packets is not used

# current issues:
# what should sensor_id be? Is there a central log collector for a given project using Rucio?

# To Do:
# make sure start/end times are correct for jobs with multiple files
# option to skip files where source/dest are the same subnet
# support for ipv6?? currently all logs say: "IPv6: indeterminate"

import sys
import re
import socket
import json
from urllib.parse import urlparse
from ipaddress import IPv4Address
import os
import argparse
from datetime import datetime

# global dict to collect results
all_jobs = {}

# only save results for file transfers > min_file_size
min_file_size = 1024*2024*10  # 10MB

def extract_info(line,deidentify):
    # Regular expression patterns for each field
    source_url_pattern = r'Source\s+url:\s+(https?://(\S+))'
    dest_url_pattern = r'Dest\s+url:\s+(https?://(\S+))'
    job_id_pattern = r'Job\s+id:\s+([\w-]+)'
    file_size_pattern = r'File\s+size:\s+(\d+)'
    num_streams_pattern = r'TCP\s+streams:\s+(\d+)'

    # to get start time, match 'TRANSFER:ENTER' and extract date string after 'INFO'
    start_time_pattern = r'INFO\s+([A-Za-z]{3},\s+\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+\d{2}:\d{2}:\d{2})\s+\+\d{4}.*?TRANSFER:ENTER'
    # to get end time, match 'TRANSFER:EXIT' and extract date string after 'INFO'
    end_time_pattern = r'INFO\s+([A-Za-z]{3},\s+\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+\d{2}:\d{2}:\d{2})\s+\+\d{4}.*?TRANSFER:EXIT'


    # Extracting each field using separate regex patterns
    source_url = re.search(source_url_pattern, line)
    dest_url = re.search(dest_url_pattern, line)
    job_id = re.search(job_id_pattern, line)
    num_streams = re.search(num_streams_pattern, line)
    file_size_match = re.search(file_size_pattern, line)
    start_time_match = re.search(start_time_pattern, line)
    end_time_match = re.search(end_time_pattern, line)

    # Constructing the extracted data dictionary
    extracted_data = {}

    if source_url:
        parsed_url = urlparse(source_url.group(1))
        source_host = parsed_url.hostname
        source_port = parsed_url.port
        if source_host:
            deidentified_ip = ip_lookup(source_host, deidentify)
            extracted_data["source_host"] = deidentified_ip
            extracted_data["source_port"] = source_port

    if dest_url:
        parsed_url = urlparse(dest_url.group(1))
        dest_host = parsed_url.hostname
        dest_port = parsed_url.port
        if dest_host:
            deidentified_ip = ip_lookup(dest_host, deidentify)
            extracted_data["dest_host"] = deidentified_ip
            extracted_data["dest_port"] = dest_port

    if job_id:
        extracted_data["job_id"] = job_id.group(1)

    if file_size_match:
        file_size = int(file_size_match.group(1))
        extracted_data["file_size"] = file_size

    if start_time_match:
        # XXX: fix for multiple jobs with same ID!!
        date_string = start_time_match.group(1)
        # Convert date string to datetime object
        log_datetime = datetime.strptime(date_string, "%a, %d %b %Y %H:%M:%S")
        # Get Unix time (Epoch time)
        unix_time = log_datetime.timestamp()
        extracted_data["start_time"] = unix_time
        # Format datetime for 'timestamp' field
        formatted_time = log_datetime.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]  # Exclude microseconds last three digits
        extracted_data["timestamp"] = formatted_time
        #print ("Start time match: ", extracted_data)

    if end_time_match:
        date_string = end_time_match.group(1)
        # Convert date string to datetime object
        log_datetime = datetime.strptime(date_string, "%a, %d %b %Y %H:%M:%S")
        # Get Unix time (Epoch time)
        unix_time = log_datetime.timestamp()
        extracted_data["end_time"] = unix_time
        #print ("end time match: ", extracted_data)


    if num_streams:
        extracted_data["num_streams"] = int(num_streams.group(1))

    return extracted_data

def ip_lookup(hostname,deidentify):
    ip_address = socket.gethostbyname(hostname)
    ip_address = IPv4Address(ip_address)
    ip_address = str(ip_address)
    if deidentify:
        ip_address = ".".join(ip_address.split('.')[:-1]) + ".1"
    return ip_address

def read_file(filename):
    try:
        with open(filename, 'r') as file:
            for line in file:
                #print ("checking line: ", line)
                data = extract_info(line,deidentify)   # check if this line contains anything useful
                if data:
                    #print ("Got Data: ", data)
                    job_id = data.get("job_id") # assumes job_id is the 1st thing returned
                    if job_id: # if got a job_id
                        #print ("checking if job_id is in dict ", job_id)
                        if job_id not in all_jobs: 
                            # first time seeing this job_id, create dict entry
                            #print ("Creating new dict for job_id: ", job_id)
                            all_jobs[job_id] = {}  # Initialize a new dictionary for this job_id
                            all_jobs[job_id]['meta'] = {  # Initialize a new dictionary for this job_id
                                "flow_type": "fts",
                                "sensor_id": "FTS",  # XXX: ask what to use for this
                                "num_files": 0,
                                "total_file_size": 0,
                                "start_time": 0,
                                "end_time": 0,
                                "protocol": "tcp",
                                "src_asn": 0, 
                                "dst_asn": 0
                            }
                        current_job_id = job_id
                    else:
                        if data and isinstance(data.get("file_size"), int) and data.get("file_size") > 0:
                            #print ("found File Size for job_id: ", current_job_id, data)
                            all_jobs[current_job_id]['meta']["num_files"] += 1
                            #print ("increased file size from %d by %d bytes" % (all_jobs[current_job_id]['meta']["total_file_size"], data.get("file_size")))
                            all_jobs[current_job_id]['meta']["total_file_size"] += data.get("file_size")
                        else:
                            # Update other fields directly
                            #print ("adding fields to job_id: ", current_job_id, data)
                            all_jobs[current_job_id]['meta'].update(data)
                    if debug_mode:
                        print("Data for job_id: ", job_id)
                        print(all_jobs[current_job_id])
                        print("")

        # file done, so now fill in 'values' part of JSON object, for example:
        # "values": {"num_packets": 217360, "num_bits": 2608321768, "duration": 21.265625, "packets_per_second": 10221.19,
        # "bits_per_second": 122654366.754}, "type": "fts", "start": 1712651652.164, "end": 1712651673.43}

        if all_jobs[current_job_id]['meta']["end_time"]:   # end time should be the last to get filled in
            nbytes = all_jobs[current_job_id]['meta']["total_file_size"]
            duration = all_jobs[current_job_id]['meta']["end_time"] - all_jobs[current_job_id]['meta']["start_time"]
            all_jobs[current_job_id]['values'] = {}
            job = all_jobs[current_job_id]['values']
            job['num_packets'] = nbytes / 1500
            job['num_bits'] = nbytes * 8
            job['duration'] = duration
            job['type'] = "fts"
            if duration > 0:
                job['packets_per_second'] = round(job['num_packets'] / duration,3)
                job['bits_per_second'] = round(job['num_bits'] / duration,3)
            else:
                print ("Error: duration = 0")
                print (all_jobs[current_job_id])
                sys.exit()

    except FileNotFoundError:
        print("File not found:", filename)
    except Exception as e:
        print("An error occurred:", e)
    
    return 

def convert_json(data):
    # dont need to save job_id in final results, so loop over data and reorg the JSON struct a bit
    new_data = []
    for key, object in data.items():
        #print (key, object)
        new_obj = {
           "@timestamp": object['timestamp'],
           "meta": object['meta'],
           "values": object['values']
        }
        new_data.append(new_obj)

    return (new_data)
        
def write_to_json(data, output_file):

    # Remove entries with file size less than min_file_size
    filtered_data = {job_id: job_data for job_id, job_data in data.items() if job_data['meta'].get("total_file_size", 0) >= min_file_size }

    # Iterate over each job and move 'timestamp' to the top-level
    for job_data in filtered_data.values():
        job_data['timestamp'] = job_data['meta'].pop('timestamp', None)

    # reformat JSON to not include job_id
    filtered_data = convert_json(filtered_data)

    with open(output_file, 'w') as json_file:
        for record in filtered_data:
             json_file.write(json.dumps(record) + '\n')


def process_files(directory,deidentify):
    file_cnt = 0
    for root, dirs, files in os.walk(directory):
        num_files = len(files)
        print(f"Directory: {root}, Number of Files: {num_files}")
        for file in files:
            if file.endswith('.json'):
                continue  # Skip files ending with .json
            file_path = os.path.join(root, file)
            if debug_mode:
                 print("Reading file: ", file_path)
            read_file(file_path)
            file_cnt += 1
            if file_cnt % 1000 == 0:
                print ("processed %d files" % file_cnt)
                # for debugging, return after 1st 1000 files
                print ("Debugging! Exiting now. ")
                return 
    return 

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Read Rucio FTS logs and convert them into a JSON format that can be fed to the NetSage pipeline.")
    parser.add_argument("-d", "--directory", help="Top-level directory containing the log files. Default is the current directory.", default=".")
    parser.add_argument("-o", "--output", help="Output filename for JSON results. Default is 'fts-netsage.json'.", default="fts-netsage.json")

    parser.add_argument("-nd", "--nodeidentify", action="store_false", help="Flag to not deidentify IPs.")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode")
    args = parser.parse_args()

    top_directory = args.directory
    output_file = args.output
    deidentify = args.nodeidentify
    debug_mode = args.debug

    process_files(top_directory, deidentify)
    write_to_json(all_jobs, output_file)

    print ("Done. Results in file: ", output_file)


