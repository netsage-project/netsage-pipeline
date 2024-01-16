#!/usr/bin/env python3

# convert Globus transfer logs to format compatible with NetFlow collector
#
# expects logs to have the following values:
# "DATE=20240107092754.223249 HOST=data1.frontera.tacc.utexas.edu PROG=globus-gridftp-server NL.EVNT=FTP_INFO START=20240107092753.658868 USER=yifan97 FILE=/scratch1/09397/yifan97/cantilever/cantilever_3d_1.4_densified.tar.gz2 BUFFER=235104 BLOCK=4194304 NBYTES=218103808 VOLUME=/ STREAMS=4 STRIPES=1 DEST=[141.211.212.174] TYPE=RETR CODE=226 TASKID=0f7ec55a-ab48-11ee-be6c-f11924dc2d22"
#
# XXX not done!
#  problem with routine to combine tasks. Only generating 1 task at the moment....
#   need to rewrite combine_by_taskID!!


import argparse, sys, json
import pandas as pd
import numpy as np
import socket
from datetime import datetime
from collections import defaultdict

MIN_XFER_SIZE = 10000  # ignore tiny files

# remove NetLogger fields not needed and/or privacy reasons
keys_to_remove = ['DATE', 'PROG', 'USER', 'NL.EVNT', 'FILE', 'VOLUME', 'TYPE', 'CODE', 'STRIPES', 'retrans', 'BUFFER', 'BLOCK'] 

def combine_by_taskID(data_list, times_by_taskid):

    # Dictionary to store the sum of 'NBYTES' and other data items for each 'TASKID'
    # start_time = 'START' of 1st line with new TASKID
    # end_time = 'DATE' of last line with new TASKID
    #  XXX: note: could also probably use pandas for this...

    sum_bytes_by_taskid = defaultdict(lambda: {'NBYTES': 0, 'NUM_FILES' : 0})

    # Loop over filtered_data_list and sum 'NBYTES' while including other data items
    for data_dict in data_list:
        task_id = data_dict.get('TASKID')
        sum_bytes_by_taskid[task_id].update(data_dict)  # Include other data items XXX: only do this 1st time?

        nbytes = data_dict.get('NBYTES', 0)
        sum_bytes_by_taskid[task_id]['NBYTES'] += nbytes
        sum_bytes_by_taskid[task_id]['NUM_FILES'] += 1
        sum_bytes_by_taskid[task_id]['start_time'] = times_by_taskid[task_id]['start']
        sum_bytes_by_taskid[task_id]['end_time'] = times_by_taskid[task_id]['end']
        #print (f"nbytes = {nbytes}, total bytes = {sum_bytes_by_taskid[task_id]['NBYTES']}")

    # Generate a new list of dictionaries with the sum of 'NBYTES' and other data items for each 'TASKID'
    result_list = list(sum_bytes_by_taskid.values())

    return (result_list)

def convert_globus_to_netflow(input_file):
    # Read file into a DataFrame
    print("Loading file: ", input_file)

    data_list = []  # List to store dictionaries
    times_by_taskid = {}  # Dictionary to store 'start_time' and 'end_time' for each 'TASKID'

    prev_task_id = ""
    with open(input_file, 'r') as file:
        # Iterate through each line in the file
        for line in file:
            #print ("parsing line: ", line)
            # strip splunk added stuff from NetLogger line
            date_index = line.find("DATE")
            if date_index != -1:
               nl = line[date_index:]
            else:
               #print ("DATE not found")
               continue   # skip lines not containing 'DATE'
            # Strip any quotes
            nl = nl.strip('"')  # XXX not working????
            #print ("Got line: ", nl)

            # Split the string into individual name-value pairs
            pairs = nl.split()

            # Create a dictionary from the name-value pairs
            #data_dict = dict(pair.split('=') for pair in pairs)

            # strip above not working, but this works. Not sure why this is needed
            data_dict = {key: value.strip('"') for key, value in (pair.split('=') for pair in pairs)}

            # convert to int
            data_dict['NBYTES'] = int(data_dict['NBYTES'])
            data_dict['DATE'] = float(data_dict['DATE'])
            data_dict['START'] = float(data_dict['START'])

            #keep track of start/end times
            task_id = data_dict.get('TASKID')
            if task_id != prev_task_id:
                print ("*** got new taskID: ", task_id)

            if task_id not in times_by_taskid: #initialize
#                print ("initializing start time to START", data_dict['START'])
#                print ("initializing end time to DATE", data_dict['DATE'])
                times_by_taskid[task_id] = {}
                times_by_taskid[task_id]['start'] = data_dict['START']
                times_by_taskid[task_id]['end'] = data_dict['DATE'];
            if times_by_taskid[task_id]['start'] < data_dict['START']:
#                print ("  setting start time to ", data_dict['START'])
                times_by_taskid[task_id]['start'] = data_dict['START'] # find smallest 'start' for this task
            if times_by_taskid[task_id]['end'] > data_dict['DATE']:
#                print ("  setting end time to ", data_dict['DATE'])
                times_by_taskid[task_id]['end'] = data_dict['DATE'] # find largest 'date' for this task

            for key in keys_to_remove: # clean up stuff no longer using
                if key in data_dict:
                    removed_value = data_dict.pop(key)
 
            # Append the dictionary to the list
            if data_dict['NBYTES'] > MIN_XFER_SIZE:
                data_list.append(data_dict)

            prev_task_id = task_id
   

    print ("\n start/end times: ", times_by_taskid)

    print ("\n Combining by TaskID...")
    combined_list = combine_by_taskID(data_list, times_by_taskid)

    # Print the resulting list
    print(f"\n Result List ({len(combined_list)} items)")
    print(combined_list)
    return combined_list

def output_to_json(result_list, output_file):


    print(f'\nConverting to JSON.... ')

    # all logs have the same source IP
    hostname = result_list[0]['HOST']
    try:
        src_ip = socket.gethostbyname(hostname)
        #print(f'The IPv4 address of {hostname} is {src_ip}')
    except socket.error as e:
        print(f'Error: {e}')

    # Convert DataFrame to the desired JSON structure 
    netsage_format_list = []

    for item in result_list:
       # add items to match netflow format
       task = {}
       dst_ip = item['DEST'].replace("[", "").replace("]", "")
       task['@timestamp'] = item['end_time']
       task['meta'] = {
           "flow_type": "globus",
           "src_port": 443,
           "dst_port": 50001,
           "sensor_id": "Globus Logs",
           "src_ip": src_ip,
           "protocol": "tcp",
           "num_files": item['NUM_FILES'],
           "dst_ip": dst_ip,
           "src_asn": 0,
           "dst_asn": 0
       }

       task['values'] = {
         "num_packets":  int(item['NBYTES'] / 1500), # not correct for Jumbo frames, but no way to know...
         "num_bits": item['NBYTES'] * 8,
         "duration": float(item['end_time']) - float(item['start_time']),
         "packets_per_second": 1000,
         "bits_per_second": 1000
       }
       task['type'] = "globus"
       task['start'] = item['start_time']
       task['end'] = item['end_time']

       netsage_format_list.append(task)


    print(f'Done Converting to JSON.... ')
    print (netsage_format_list)

    with open(output_file, 'w') as json_file:
         json.dump(netsage_format_list, json_file, indent=2)

    print(f'\nConversion completed. NetFlow-compatible file saved to {output_file}')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert Globus Transfer Log file to NetFlow-compatible format.")
    parser.add_argument("input_file", help="Input log file")
    parser.add_argument("output_file", help="Output NetFlow-compatible file")

    args = parser.parse_args()
    results = convert_globus_to_netflow(args.input_file)
    output_to_json(results, args.output_file)

    print("Done.")

