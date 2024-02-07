#!/usr/bin/env python3
#
# get Globus logs from TACC splunk server
#
# By default, gets logs from midnight 2 days ago to midnight last night

# note: pip3 default install of splunklib did not work!
#  but this did: pip install git+https://github.com/splunk/splunk-sdk-python.git

# needs a config file with the following: (default = splunk_config.ini)
#[splunk]
#host = scribe.tacc.utexas.edu
#port = 8090
#username = 
#password = 

import sys
import time
import csv
import splunklib.client as client
import splunklib.results as results
from datetime import datetime, timedelta
import configparser
import argparse
import os

# By default, gets logs from midnight 2 days ago to midnight last night
# Change ndays below to get more data. eg: to get a week, set ndays to 8
# note that Globus logs seem to only get uploaded to splunk once/day
#
ndays = "2"

def main(config_file, output_dir):
    # Read configuration from config.ini file
    config = configparser.ConfigParser()
    try:
        config.read(config_file)
    except:
        print ("Config file not found! ", config_file)
        exit(1)

    # Splunk connection information
    try:
        host = config['splunk']['host']
        port = config['splunk'].getint('port')
        username = config['splunk']['username']
        password = config['splunk']['password']
    except:
        print ("Config file not found or missing fields! ", config_file)
        exit(1)

    today = datetime.now()
    yesterday = today - timedelta(days=1)
    yesterday_str = yesterday.strftime("%Y-%m-%d")

    # Output file name
    output_file = output_dir+"/globus_logs."+yesterday_str+".nl"
    print("Saving results to file: ", output_file)

    file = open(output_file, mode='w')

    # Set up Splunk connection
    service = client.connect(
        host=host,
        port=port,
        username=username,
        password=password
    )

    # midnight 'ndays' ago to midnight last night
    #earliest_time =  "-2d@d" # midnight yesterday
    earliest_time = "-"+ndays+"d@d"
    kwargs_export = {"earliest_time": earliest_time,
                     "latest_time": "-1d@d",
                     "search_mode": "normal",
                     "output_mode": "json"}

    searchquery_export = "search index=globust"

    print("Collecting logs from Splunk.... (this may take a while)")
    exportsearch_results = service.jobs.export(searchquery_export, **kwargs_export)

    # Get the results and display them using the JSONResultsReader
    reader = results.JSONResultsReader(exportsearch_results)
    count = 0
    for result in reader:
        if isinstance(result, dict):
            # print("Result: %s" % result)
            file.write(result['_raw'])
            file.write("\n")
            count += 1
            if count % 10000 == 0:
                print("   Wrote %d logs to file" % count)
        elif isinstance(result, results.Message):
            # Diagnostic messages may be returned in the results
            print("Message: %s" % result)

    print("Wrote a total of %d log entries to file %s " % (count, output_file))

    file.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Get Globus Logs from Splunk.')
    parser.add_argument('-c', '--config', type=str, default='splunk_config.ini',
                        help='config file containing user/password, default = splunk_config.ini')
    parser.add_argument('-o', '--outputdir', type=str, default='.',
                        help='output directory, default = .')
    args = parser.parse_args()

    main(args.config, args.outputdir)

    print("\nDone.")


