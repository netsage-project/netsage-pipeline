#!/bin/bash
# Logstash restart script
# Sometimes logstash is slow to stop. Trying twice normally works.
# This is a simple way to make sure logstash has stopped before we try to start it

/sbin/service logstash stop
sleep 7                                                    
/sbin/service logstash stop
sleep 3

logstash_status=$(/sbin/service logstash status)  
if [[ $logstash_status =~ .*"active (running)".*|"logstash is running" ]]; then
    echo "Logstash has not stopped. Cannot restart."
else
    echo "Logstash has stopped. Attempting to restart."
    /sbin/service logstash start
fi
