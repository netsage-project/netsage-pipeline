#!/usr/bin/env python3
#
# convert Globus transfer logs to format compatible with NetFlow collector
#
# expects logs to have the following values:
# "DATE=20240107092754.223249 HOST=data1.frontera.tacc.utexas.edu PROG=globus-gridftp-server NL.EVNT=FTP_INFO START=20240107092753.658868 USER=yifan97 FILE=/scratch1/09397/yifan97/cantilever/cantilever_3d_1.4_densified.tar.gz2 BUFFER=235104 BLOCK=4194304 NBYTES=218103808 VOLUME=/ STREAMS=4 STRIPES=1 DEST=[141.211.212.174] TYPE=RETR CODE=226 TASKID=0f7ec55a-ab48-11ee-be6c-f11924dc2d22"
#

import argparse, sys, json, socket

MIN_XFER_SIZE = 10000  # ignore tiny files

# remove NetLogger fields not needed and/or privacy reasons
keys_to_remove = ['PROG', 'USER', 'NL.EVNT', 'FILE', 'VOLUME', 'TYPE', 'CODE', 'STRIPES', 'retrans', 'BUFFER', 'BLOCK'] 

def combine_by_taskID(transfer_list):
    # this routine does the following:
    # 1) sorts the data by taskID
    # 2) needs to loop over data twice, as start/end times might vary in sorted list

    # sort by task ID, then loop over data to find start/end
    sorted_list = sorted(transfer_list, key=lambda x: x['TASKID'])

    result_list = []
    times_by_taskid = {}  # Dictionary to store 'start_time' and 'end_time' for each 'TASKID'
    prev_task_id = -1

    # first loop over data to get start/end times
    for task in sorted_list:
        #print ("checking task: ",task)
        task_id = task.get('TASKID')
        if task_id != prev_task_id:
            times_by_taskid[task_id] = {}
            times_by_taskid[task_id]['start'] = task['START']
            times_by_taskid[task_id]['end'] = task['DATE'];
            #print ("new times entry: ", times_by_taskid[task_id]['start'], times_by_taskid[task_id]['end'])
        if task['START'] < times_by_taskid[task_id]['start']:
            times_by_taskid[task_id]['start'] = task['START'] # find smallest 'start' for this task
            #print ("found earlier start: ", times_by_taskid[task_id]['start'])
        if task['DATE'] > times_by_taskid[task_id]['end']:
            times_by_taskid[task_id]['end'] = task['DATE'] # find largest 'date' for this task
            #print ("found later end: ", times_by_taskid[task_id]['start'])
        prev_task_id = task_id

    # Next, loop over transfer_list and sum 'NBYTES' while including other data items, including start/end
    prev_task_id = -1
    for task in sorted_list:
        #print ("combining:" , task)
        task_id = task.get('TASKID')
        nbytes = task.get('NBYTES', 0)

        if task_id != prev_task_id:
            if prev_task_id != -1: # not the first time
                print (f"    Done with this taskID: # files = {combined_task['NUM_FILES']}, total bytes = {combined_task['NBYTES']}")
                result_list.append(combined_task) # append the prevous task, as done with it
                #print ("adding combined_task to list: ", combined_task)
            print ("*** got new taskID: ", task_id)
            # Create a new dictionary for each new task
            combined_task = {'TASKID': task_id, 'NBYTES': 0, 'NUM_FILES': 0}
            combined_task.update(task)  # Include other data items 
            # add times and move on to next task
            combined_task['start_time'] = times_by_taskid[task_id]['start']
            combined_task['end_time'] = times_by_taskid[task_id]['end']
            combined_task['duration'] = times_by_taskid[task_id]['end'] - times_by_taskid[task_id]['start']

        combined_task['NBYTES'] += nbytes
        combined_task['NUM_FILES'] += 1
        prev_task_id = task_id

    # dont forget the last task
    print (f"    Done with this taskID: # files = {combined_task['NUM_FILES']}, total bytes = {combined_task['NBYTES']}")
    result_list.append(combined_task) # append the prevous task, as done with it
    print("\nCombined %d transfers into %d tasks " % (len(transfer_list), len(result_list)))

    # Generate a new list of dictionaries with the sum of 'NBYTES' and other data items for each 'TASKID'
    #result_list = list(sum_bytes_by_taskid.values())

    return (result_list)

def convert_globus_to_netflow(input_file):
    # Read file into a DataFrame
    print("Loading file: ", input_file)

    data_list = []  # List to store dictionaries
    num_skipped = 0

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

            # Split the string into individual name-value pairs
            pairs = nl.split()
            #print ("pairs: ", pairs)

            # simple strip of nl.strip('"') not working, but this works. Not sure why this is needed
            # Strip any quotes
            transfer = {key: value.strip('"') for key, value in (pair.split('=') for pair in pairs)}

            transfer['NBYTES'] = int(transfer['NBYTES'])
            transfer['DATE'] = float(transfer['DATE'])
            transfer['START'] = float(transfer['START'])

            #print ("transfer:", transfer)

            for key in keys_to_remove: # clean up stuff no longer using
                if key in transfer:
                    removed_value = transfer.pop(key)
 
            # Append the dictionary to the list
            if transfer['NBYTES'] > MIN_XFER_SIZE:
                #print ("appending: ", transfer)
                data_list.append(transfer)
            else:
                num_skipped += 1
                #print ("Skipping small file transfer of %d bytes" % transfer['NBYTES'])


    print ("Skipped a total of %d small transfers" % num_skipped)

    # Count the number of unique task IDs
    unique_task_ids = set(task['TASKID'] for task in data_list)
    num_unique_task_ids = len(unique_task_ids)
    print(f"\nNumber of unique task IDs: {num_unique_task_ids}")

    print ("\nCombining %d transfers by TaskID..." % len(data_list))
    combined_list = combine_by_taskID(data_list)

    # Print the resulting list
    #print("Combined list: ")
    #print(combined_list)
    return combined_list


def output_to_json(result_list, output_file):

    print(f'\nConverting to JSON.... ')

    hostname = result_list[0]['HOST'] # all logs have the same source IP
    #print ("   Looking up IP for host: ", hostname)
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

       # fill in 'values' part of JSON object
       task['values'] = {}
       task['values']['num_packets'] = int(item['NBYTES'] / 1500)  # not correct for Jumbo frames, but no way to know...
       task['values']['num_bits'] = item['NBYTES'] * 8
       task['values']['duration'] = item['duration']
       task['values']['packets_per_second'] = round(task['values']['num_packets'] / item['duration'],3)
       task['values']['bits_per_second'] = round(task['values']['num_bits'] / item['duration'],3)

       task['type'] = "globus"
       task['start'] = item['start_time']
       task['end'] = item['end_time']

       netsage_format_list.append(task)


    print(f'Done Converting to JSON.... ')
    #print (netsage_format_list)

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

