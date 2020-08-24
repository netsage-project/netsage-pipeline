#!/usr/bin/env bash 
function netflow 
{
nfreplay -H 127.0.0.1 -p 9999  -r nfcapd-ilight-anon-20200114 -v 9 -d 1000 
}
function sflow
{
nfreplay -H 127.0.0.1 -p 6343 -r sflow_anon.nfcapd -v 9 -d 1000 
}
function acct 
{
nfreplay -H 127.0.0.1 -p 9996  -r nfcapd-ilight-anon-20200114 -v 9 -d 1000 
}

function sflowacct
{
nfreplay -H 127.0.0.1 -p 9997 -r sflow_anon.nfcapd -v 9 -d 1000 
}

sflow
