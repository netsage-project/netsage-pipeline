---
id: importer
title: Legacy Importer
sidebar_label: Importer
---
A netsage-netflow-importer reads any new nfcapd files that have come in after a configurable delay and writes the results to the "netsage_deidentifier_raw" RabbitMQ queue.
All flow data waits in the queue until it is read in and processed by the logstash pipeline.

To read nfcapd files, the importer uses an nfdump command with the "-a" option to aggregate raw flows within the file by the "5-tuple," i.e., the source and destination IPs, ports, and protocol. The  "-L" option is used to throw out any aggregated flows below a threshold number of bytes. This threshold is specified in the importer config file. 

NOTE: The importer will be deprecated in the future and replace with a logstash operation.

### Configuration
Configuration files for the importer are netsage_netflow_importer.xml and netsage_shared.xml in /etc/grnoc/netsage/deidentfier/. Comments in the files briefly describe the options. See also the Deployment pages in these docs.

To avoid re-reading nfcapd files, the importer stores the names of files that have already been read in /var/cache/netsage/netflow_importer.cache. 
