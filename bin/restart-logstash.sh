#!/bin/bash

# Logstash restart script
# Sometimes logstash is slow to stop. Trying twice normally works.
# This is a simple way to make sure logstash has stopped before we try to start it

echo "$(date)"
echo "stopping logstash"
/sbin/service logstash stop
sleep 30
    echo "(after 30s) ls /tmp/:"
    ls -l /tmp

echo "$(date)"
echo "stopping logstash"
/sbin/service logstash stop
sleep 30
    echo "(after 30s) ls /tmp/:"
    ls -l /tmp

logstash_status=$(/sbin/service logstash status)
if [[ $logstash_status =~ .*"active (running)".*|"logstash is running" ]]; then
    #echo $logstash_status
    echo "Logstash has not stopped. Cannot restart."
else
    echo "$(date)"
    echo "Logstash has stopped."
    echo "Attempting to start logstash."
    /sbin/service logstash start
fi
