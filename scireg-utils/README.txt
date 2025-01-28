# This directory contains files for building and maintaining the NetSage Science Registry.
# See: https://netsage.io/scienceregistry

Contents of this directory

Current scripts/programs:
  - add_new_scireg.py: script to add new entry to scireg.json file, or cleanup file
  - scireg2mmdb.go : builds mmdb from JSON
  - dump_mmdb.go : dump entire mmdb for debugging
  - Makefile : builds go tools
      do: make init; make

Steps to update Science Registry:
  1) download current JSON file and template file: 
       wget https://epoc-rabbitmq.tacc.utexas.edu/NetSage/scireg.json
       wget https://epoc-rabbitmq.tacc.utexas.edu/NetSage/scireg.template.json

  2) add new entries to template using your favorite editor, then do:
       add_new_scireg.py -i scireg.json -t scireg.template.json -o scireg-update.json

     or to cleanup existing JSON if edited directly:
       add_new_scireg.py --clean -i newScireg.json -o newestScireg.json


  3) convert to mmdb:
       scireg2mmdb -i newScireg.json -o newScireg.mmdb

  4) test using mmdblookup tool:
      mmdblookup --file newScireg.mmdb --ip 140.221.68.1

  4) copy updated files to repo

For communities.mmdb generation:
  1) combine JSON for each community into a single file:
     jq -s '[.[][]]' community-*.json > combined.json

  2) build mmdb:
      scireg2mmdb -i combined.json -o communities.mmdb


Other useful tools:

To merge 2 Science Registry files, only keeping unique entries
    merge_scireg.py newScireg.json newScireg-testing.json merged.json


----------------------------------------------

Transition tools:
  - reformat_scireg.py : read old style of Science Registry JSON, and convert to new format
       -option to check if IP is pingable for /32 subnets
    sample use:
       reformat_scireg.py -i scireg.json -o scireg.new-format.json 

