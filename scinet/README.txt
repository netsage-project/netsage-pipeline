
This directory contains a set of scripts to convert SCinet DB data to files for the NetSage pipeline.

*** Important ***

These scripts only partially worked. Only about 50% of the subnets got tagged correctly.
More will be needed next year to determine the problem.

Approach #1: build a custom scireg.mmdb file containing SCinet booth info.
    - this did not work. reason unknown

Approach #2: Build a custom 'member-list' file for the SCinet ASN
    - this worked on about 50% of the subnets. Seemed to fail on smaller subnets
       for an unknown reason

#
*****************

Steps to create member-list file

To query SCinet DB:

First log into https://scinet.supercomputing.org/intranet_api/v1/network using scinet username/pw

Then get these using a browser, and save:

https://scinet.supercomputing.org/intranet_api/v1/exhibitor_organization/?detail=1&format=json&limit=0
   save as: orgs.json

https://scinet.supercomputing.org/intranet_api/v1/networked_connection/?detail=1&format=json&limit=0
   save as: connections.json
   use this file to look up booth names in orgs.json

https://scinet.supercomputing.org/intranet_api/v1/network/?detail=1&format=json&limit=0
   save as: networks.json
   for these networks, use the 'name' field

Then run: 

Combine the 3 SCinet JSON files together:
   ./scinet-combine.py
Generate member-list.rb file
   ./scinet2memberlist.py
Generate mmdb file (Science Registry format)
   ./json2mmdb.py

Then copy to SCinet netsage host:
   scp scinet.mmdb scinet-members-list.rb netsage-ingest:
   ssh netsage-ingest 'sudo cp scinet.mmdb /home/dojosout/netsage-pipeline/data/cache/scireg.mmdb'
   ssh netsage-ingest 'sudo cp scinet-member-list.rb /home/dojosout/netsage-pipeline/data/cache/scireg.mmdb'


