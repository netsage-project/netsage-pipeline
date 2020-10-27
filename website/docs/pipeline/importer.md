---
id: importer
title: Importer
sidebar_label: Importer
---
### Importer 

A netsage-netflow-importer-daemon reads any new nfcapd files that have come in after a configurable delay. The importer aggregates flows within each file, and writes the results to the netsage_deidentifier_raw queue rabbit queue.


## Importer

NOTE: Importer will be deprecated in the future and replace with a logstash operation.

### Configuration
configuration files for the importer are `netsage_netflow_importer.xml` and `netsage_shared.xml` in `/etc/grnoc/netsage/deidentifer/`. Comments in the files briefly describe the options.

Names of files have already been read are stored in /var/cache/netsage/netflow_importer.cache. 

### Internals

The importer uses the nfdump command with -a to aggregate within the file, and -L `threshold` to throw out any flows under a flow size threshold. 

For cenic, data from the importer first goes into a ...prefilter queue. A netsage-flow-filter-daemon reads it out, removes some flows , then sends it to the ...raw queue.
A ...raw2 or ...fake queue is created for historical reasons but never actually holds any messages.

All flow data waits in the netsage_deidentifier_raw queue until it is processed by the logstash pipeline as follows.

