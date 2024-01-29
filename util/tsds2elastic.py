#!/usr/bin/env python3

# This is a program to convert the JSON output of a tsds query 
# to an equivilent JSON recorded formatted for NetSage ElasticSearch DB
#
# Field Mappings
#    Elastic             TSDS
#    meta.device         node
#    meta.link_name      link_name
#    meta.name           intf
#    meta.description    description
#    meta.speed          speed (or extract from link_name if NULL) (in Mbps)
#    meta.id	         meta.device + "::" + meta.name
#    meta.type           "interface"
#    meta.interval       values.input[N][0] - values.input[N-1][0]  # not stored, but maybe it should be?
#    @timestamp          values.input[N][0]   # TSDS returns an array, 1 per sample
#    if_in_bits.val      does not exist, so set to -1
#    if_in_bits.delta    values.input[N][1] * meta.interval
#    if_in_bits.rate     values.input[N][1] 
#    if_out_bits.val     same as above, but using values.output
#    if_out_bits.delta
#    if_out_bits.rate

import json
import sys
import datetime
import re
import os as _os

# Set input and output file names
output_file = "send_to_elastic.json"
input_dir = "."


of  = open(output_file, "w")

# Loop over all *.dat files in input directory
for input_file in _os.listdir(input_dir):
    in_bits_results = []
    out_bits_results = []
    timestamps = []

    if input_file.endswith(".dat"):
        # Read input from file
        with open(_os.path.join(input_dir, input_file), "r") as f:
           json_str = f.read()
           # Parse the file as a JSON object
           try:
               json_obj = json.loads(json_str)
           except json.JSONDecodeError:
                 continue  # skip any invalid JSON objects
        print(f"working on file: {input_file}")

        results = json_obj['results']
        #print(f"** length of results array = {len(results)}")

        for i in range(len(results)):   # loop over each interface/linkname
            try:
                meta_description = results[i]['description']
            except:
                continue
            meta_name = results[i]['intf']
            meta_link_name = results[i]['link_name']
            meta_device = results[i]['node']
            print ("    collecting data for link: ",meta_link_name)

            try:
                 meta_speed = results[i]['speed'] * 1000000
            except:
	         # Use regular expression to find the number before the target string
                 match = re.search(r'\d+(?=GE)', meta_link_name)
                 # old try: match = re.search(r"(\d+)\D+GE", meta_link_name)
	         # Extract the number if a match is found
                 if match:
                    meta_speed = int(match.group()) * 1000  # convert to Mbps
                    #print (f"Setting speed to {meta_speed} from link_name")
                 else:
                    #print("No match found")
                    meta_speed = 0

            meta_id = meta_device + "::" + meta_name
            meta_type = "interface"
            print(f"Link_name: {meta_link_name}, Descr:{meta_description}, Name: {meta_name}, Device: {meta_device}, Speed: {meta_speed}, ID: {meta_id}, {meta_type}")

            # Generate 1 line of output for each value in results array
            in_array =  results[i]['values.input']
            out_array =  results[i]['values.output']
            #print ("Size of in_array: ", len(in_array))
            #print ("Size of out_array: ", len(out_array))
            if not in_array or len(in_array) == 0:  # skip if no data
                 continue
            if len(in_array) != len(out_array):
                 print ("Error: inputs and outputs from TSDS do not match!")
                 sys.exit(-1)

            cnt = interval = 0
            values = {}
            values['if_in_bits'] = {}
            values['if_out_bits'] = {}
            prev_val = []
    
            # first loop over inputs and build an array of results
            for i in range(len(in_array)):
                if not in_array[i][1]:   # If value == null
                   continue
    
                val = in_array[i]
                if i == 0:  
                    prev_val = val
                    continue  # skip first array element, not that there may be several before the first non-zero value
    
                if interval == 0:  # compute interval based on 1st 2 values
                    save_val = val # for debugging
                    try:
                         interval = val[0] - prev_val[0]
                         #print (f"computed interval {interval} from {val[0]} and {prev_val[0]}")
                         prev_val = val
                         if interval == 0: # if still 0, continue again
                             continue
                    except:
                         prev_val = val
                         continue
                    if interval < 0 or interval > 1000:
                         print(val)
                         print(save_val)
                         print ("Interval: ", interval)
                         print ("Error: invalid interval! Exiting ")
                         sys.exit()
                    else:
                         print(f"*** using interval of {interval} for file {input_file} ***")
                try:
                    bits = -1 # does not exist in TSDS
                    delta = int(val[1] * interval)
                    rate = round(val[1], 3)
                except:
                    bits = delta = rate = 0
                if delta <= 0: # should not happen?
                     print(f"Error: delta < 0, interval: {interval}, In Delta: {delta}, In rate: {rate}")
                     print(val)
                     print(prev_val)
                     continue
    
                obj = {"val": bits, "delta": delta, "rate": rate}
                in_bits_results.append(obj)
    
                date_time = datetime.datetime.fromtimestamp(val[0])
                formatted_date_time = date_time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
                timestamps.append(formatted_date_time)
    
                cnt += 1
    
                #if cnt == 10:
                #    print (in_bits_results)
                #    print (timestamps)
    
            # next loop over output and build an array of results
            for i in range(len(out_array)):
                if not out_array[i][1]:   # If value == null
                   continue
    
                val = out_array[i]
                #print (val)
                if i == 0:
                    continue  # skip first array element
                try:
                    bits = -1 # does not exist in TSDS
                    delta = int(val[1] * interval)
                    rate = round(val[1], 3)
                except:
                    bits = delta = rate = 0
    
                if delta <= 0: # should not happen?
                     print(f"Error: delta < 0, interval: {interval}, In Delta: {delta}, In rate: {rate}")
                     print(val)
                     continue
    
                obj = {"val": bits, "delta": delta, "rate": rate}
                out_bits_results.append(obj)
                cnt += 1
    
            if len(in_bits_results) != len(timestamps):
                 print ("Error: results arrays are different sizes !")
                 sys.exit(-1)
            # loop over results array, and generate 1 JSON object per entry
            elastic_dict = {}
            meta_dict = {}
            for i in range(len(in_bits_results)):
                # Build final python dict for output as JSON
                try:
                    elastic_dict['@timestamp'] =  timestamps[i]
                except:
                    print (f"Error with array element {i}")
                    continue  # skip to next if cant get timestamp
    
                meta_dict = {
                    "name": meta_name,
                    "link_name": meta_link_name,
                    "device" : meta_device,
                    "description" : meta_description,
                    "speed" : meta_speed,
                    "id" : meta_id,
                    "type" : meta_type,
                }
                elastic_dict['meta'] = meta_dict
                
                values['if_in_bits'] = in_bits_results[i]
                try:
                    values['if_out_bits'] = out_bits_results[i]
                except:
                    values['if_out_bits'] = {}
                elastic_dict['values'] = values
    
                #debugging
                #if i < 5:
                #     #print ("Meta: ", meta_dict)
                #     print ("Elastic: ", elastic_dict)
                #     print ("\n")
                #else:
                #     sys.exit()
    
                # write the dictionary to the file as a JSON object
                json.dump(elastic_dict, of)
                of.write('\n')
    
    
of.close()
print("\n **** Done ****")
