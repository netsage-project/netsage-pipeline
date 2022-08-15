---
id: pmacct
title: Pmacct
sidebar_label: Pmacct
---
The pmacct ("p-m-account") package includes sfacctd and nfacctd daemons which receive sflow and netflow/IPFIX flows, respectively. They can also do some processing and filtering, but we use these options very minimally. (Pmacct includes other daemons, as well, but we do not use them. Here, "pmacct" will refer to sfacctd and nfacctd in general.) 

As flow data comes into the pipeline host, it is received by nfacctd and sfacctd processes which are listening on the proper ports (one process per port). 
These proceses do sampling corrections, add sensor name information, and send the flows to a rabbitmq queue.
Netsage also uses sfacctd to do some preliminary aggregation for sflow, to cut down on the work that logstash needs to do. By default, all samples, with the same 5-tuple, within each 5 minute window are aggregated into one incoming raw flow.

### Configuration
Each nfacctd and sfacctd process requires a main config file. In the bare-metal installation, these are in /etc/pmacct/. For the default docker deployment, they are in {pipeline checkout directory}/conf-pmacct/.  There are two basic versions - sfacctd.conf.ORIG and nfacctd.conf.ORIG. See comments within the files. Sensor-specific versions are created from these via a setup script.

For Netsage, pretag.map files are also required to assign a sensor name, one for each nfacctd or sfacctd process. With the docker deployment, these files are also created by a setup script. By default, these are found in the same directory as the main config files.


