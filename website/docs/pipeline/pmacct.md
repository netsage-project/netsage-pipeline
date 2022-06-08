---
id: pmacct
title: Pmacct
sidebar_label: Pmacct
---
As flow data comes into the pipeline host, it is received by nfacctd and sfacctd processes which are listening on the proper ports. 
These do sampling corrections, add sensor name information, and send the flows to a rabbitmq queue.
Netsage also uses sfacctd to do some preliminary aggregation for sflow, to cut down on the work that logstash needs to do. By default, all samples, with the same 5-tuple, within each 5 minute window are aggregated into one incoming flow.

### Configuration
For netsage, pretag.map files are required, one for each nfacctd or sfacctd process. In the bare-metal installation, these are in /etc/pmacct/. For the default docker deployment, we have one for sflow, one for netflow: sfacct-pretag.map and nfacct-pretag.map. These specify the sensor names which are added to the flows. See the comments in the files and the Deployment pages in these docs.

Configuration files are also required for each nfacctd or sfacctd process. In the bare-metal installation, these are also in /etc/pmacct/. For the default docker deployment, we have just two files - sfacctd.conf and nfacctd.conf. See comments within the files.

