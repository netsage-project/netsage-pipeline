#!/usr/bin/env python3

# convert Globus logs to format compatible with NetFlow collector
#
# Note: This program can take > 30 mins for a large globus log file.
# Breaking the work up into chunks of 100000 records seemed to help a bit

# NetSage logstash expects something that looks like this:
#{"@timestamp":"2023-12-04T17:45:05.542483407Z","meta":{"flow_type":"netflow","src_port":"35368","dst_port":"50236","src_ifindex":"641","sensor_id":"tacc_netflows","sr
#c_ip":"129.114.63.105","src_asn":"32093","protocol":"tcp","dst_ifindex":"566","dst_asn":"194","dst_ip":"128.117.210.216"},"interval":600,"values":{"num_packets":46600
#0,"num_bits":33552000000,"packets_per_second":"1570","bits_per_second":"113094214","duration":"296.673"},"type":"flow","end":1.701711245954E9,"start":1.701710949281E9
#,"@version":"1"}

# for now, assuming we can leave out the following:
#  src_ifindex, dst_ifindex interval, src_asn, dst_asn

import argparse, sys, json
import pandas as pd
import numpy as np
from datetime import datetime

MIN_XFER_SIZE = 10000  # ignore tiny files
CHUNK_SIZE = 100000  # Set the chunk size

def process_chunk(chunk):
    chunk['timestamp'] = chunk['start_time']
    chunk['source_ip'] = chunk['source_ip'].astype(str) + ".1"
    chunk['dest_ip'] = chunk['dest_ip'].astype(str) + ".1"
    chunk['packets'] = (chunk['bytes_xfered'] / 1500).round().astype(int)
    chunk['src_port'] = 443
    chunk['dst_port'] = np.random.randint(50000, 51001, size=len(chunk))
    chunk['src_asn'] = 0  # force maxmind lookup in pipeline
    chunk['dst_asn'] = 0
    chunk['duration'] = (pd.to_datetime(chunk['end_time']) - pd.to_datetime(chunk['start_time'])).dt.total_seconds()
    chunk['num_bits'] = (chunk['bytes_xfered'] * 8).astype(int)
    chunk['num_files'] = (chunk['files_xfered']).astype(int)
    chunk['packets_per_second'] = (chunk['packets'] / chunk['duration']).round(3)
    chunk['bits_per_second'] = (chunk['num_bits'] / chunk['duration']).round(3)
    return chunk[['timestamp', 'start_time', 'end_time', 'source_ip', 'dest_ip', 'src_port', 'dst_port', 'files_xfered', 'bytes_xfered', 'packets', 'duration', 'num_bits', 'packets_per_second', 'bits_per_second', 'src_asn', 'dst_asn']]

def convert_csv_to_netflow(input_file, output_file):
    # Read CSV file into a DataFrame
    print("Loading file: ", input_file)

    # Use chunksize parameter to process the file in chunks
    chunks = pd.read_csv(input_file, chunksize=CHUNK_SIZE)
    processed_chunks = []

    for chunk in chunks:
        # Remove rows where bytes_xfered < MIN_XFER_SIZE
        chunk = chunk[chunk['bytes_xfered'] >= MIN_XFER_SIZE]
        processed_chunk = process_chunk(chunk)
        processed_chunks.append(processed_chunk)

    # Concatenate processed chunks into the final DataFrame
    netflow_df = pd.concat(processed_chunks, ignore_index=True)

    print(f'   Converting to JSON.... Number of Chunks of size {CHUNK_SIZE} = {len(netflow_df) / CHUNK_SIZE} ')
    i = 0
    # Convert DataFrame to the desired JSON structure in chunks
    with open(output_file, 'w') as f:
        for _, chunk in netflow_df.groupby(np.arange(len(netflow_df)) // CHUNK_SIZE):
            print (f"   processing chunk {i}...")
            netflow_json = chunk.apply(lambda x: {
                "@timestamp": x['start_time'],
                "meta": {
                    "flow_type": "globus",
                    "src_port": str(x['src_port']),
                    "dst_port": str(x['dst_port']),
                    "sensor_id": "Globus Logs",
                    "src_ip": x['source_ip'],
                    "protocol": "tcp",
                    "num_files": x['files_xfered'],
                    "dst_ip": x['dest_ip'],
                    "src_asn": x['src_asn'],
                    "dst_asn": x['dst_asn']
                },
                "values": {
                    "num_packets": int(x['packets']),
                    "num_bits": int(x['bytes_xfered'] * 8),
                    "duration": x['duration'],
                    "packets_per_second": x['packets_per_second'],
                    "bits_per_second": x['bits_per_second'],
                },
                "type": "globus",
                "start": pd.to_datetime(x['start_time']).timestamp(),
                "end": pd.to_datetime(x['end_time']).timestamp(),
            }, axis=1).tolist()

            for record in netflow_json:
                f.write(json.dumps(record) + '\n')
            i = i+1

    print(f'   Conversion completed. NetFlow-compatible file saved to {output_file}')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert CSV file to NetFlow-compatible format.")
    parser.add_argument("input_file", help="Input CSV file path")
    parser.add_argument("output_file", help="Output NetFlow-compatible file path")

    args = parser.parse_args()
    convert_csv_to_netflow(args.input_file, args.output_file)

    print("Done.")

