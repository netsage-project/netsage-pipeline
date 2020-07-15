#!/bin/bash
# Logstash restart script
# Sometimes logstash is slow to stop. Trying twice normally works.
# We need to make sure logstash has stopped before we try to start it

service logstash stop
sleep 7                                                    
service logstash stop
sleep 3

logstash_status=$(service logstash status)  
if [[ $logstash_status =~ .*"active (running)".*|"logstash is running" ]]; then
    echo "logstash has not stopped. cannot restart."
else
     service logstash start
fi
