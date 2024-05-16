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

def main(config_file, output_dir, specified_date_str=None):

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

    # Compute the date for yesterday if no day is provided
    if specified_date_str is None:
        specified_date = datetime.now() - timedelta(days=1)
    else:
        specified_date = datetime.strptime(specified_date_str, "%Y-%m-%d")
        
    specified_date_str = specified_date.strftime("%Y-%m-%d")

    # Output file name
    output_file = os.path.join(output_dir, f"globus_logs.{specified_date_str}.nl")
    print("Saving results to file:", output_file)

    with open(output_file, mode='w') as file:

        # Set up Splunk connection
        service = client.connect(
            host=host,
            port=port,
            username=username,
            password=password
        )

        # Set up time range for the specified day
        earliest_time = specified_date.replace(hour=0, minute=0, second=0, microsecond=0)
        latest_time = specified_date.replace(hour=23, minute=59, second=59, microsecond=999999)
        earliest_time_str = earliest_time.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "-00:00"
        latest_time_str = latest_time.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "-00:00"
        print(f"Getting globus logs for times {earliest_time_str} to {latest_time_str}")

        kwargs_export = {"earliest_time": earliest_time_str,
                         "latest_time": latest_time_str,
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
                file.write(result['_raw'])
                file.write("\n")
                count += 1
                if count % 10000 == 0:
                    print(f"Wrote {count} logs to file")
            elif isinstance(result, results.Message):
                # Diagnostic messages may be returned in the results
                print("Message:", result)

        print(f"Wrote a total of {count} log entries to file {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Get Globus Logs from Splunk.')
    parser.add_argument('-c', '--config', type=str, default='splunk_config.ini',
                        help='config file containing user/password, default = splunk_config.ini')
    parser.add_argument('-o', '--outputdir', type=str, default='.',
                        help='output directory, default = .')
    parser.add_argument('-d', '--date', type=str,
                        help='date of the logs to get in YYYY-MM-DD format (default = yesterday)')
    args = parser.parse_args()

    main(args.config, args.outputdir, args.date)

    print("\nDone.")


