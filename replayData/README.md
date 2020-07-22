# Developer Tools

## testing.py

This snippet will allow you to send a single json file payload and write to rabbit mq. 

### Install

python3 -m pip install pika 

### Running the script

Simply run: ./testing.py <filename>

Example:

``` sh
./testing.py filebeat_netflow.json
```

## Replay Data

Assuming you have a valid network data capture. Simply update the netflow.sh to send netflow of sflow data.

This expects that either the collector or filebeat is running with port 9999/udp exposed.
