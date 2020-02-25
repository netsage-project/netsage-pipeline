#!/usr/bin/env bash 
if [[ $RELEASE = true ]]; then
    yum install -y grnoc-netsage-deidentifier 
else 
    for i in $(ls /tmp/*.rpm); do yum localinstall -y $i; done;
fi
