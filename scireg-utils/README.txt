Contents of this directory

Current scripts/programs:
  - scireg2mmdb.go : builds mmdb from JSON
  - dump_mmdb.go : dump entire mmdb for debugging
  - Makefile : builds go tools
      do: make init; make

To Do:
  - modify scireg2mmdb.go to append a single entry (or new script), instead of requiring step 2 below
  - program to merge any updates from google sheets to .json to complete transition (cleanup pass in progress)
  - maybe someday: program to prompt use for all scireg fields, and add to both .json and .mmdb 

Steps to update Science Registry:
  1) download current JSON file: 
       wget https://epoc-rabbitmq.tacc.utexas.edu/NetSage/scireg.json
       wget https://epoc-rabbitmq.tacc.utexas.edu/NetSage/scireg.template.jsonc
  2) add new entries to template using your favorite editor, then do:
       # strip out comments
       sed '/^[[:space:]]*\/\//d; s/\/\*.*\*\///g' scireg.template.jsonc > tmp.json
       # use jq to add this new entry to array of JSON objects
       jq --slurpfile newObject tmp.json '. += [$newObject[0]]' scireg.json > scireg.new.json

  3) convert to mmdb:
       scireg2mmdb -i scireg.new.json -o scireg.mmdb
  4) copy updated files to repo


----------------------------------------------

Transition tools:
  - reformat_scireg.py : read old style of Science Registry JSON, and convert to new format
       -option to check if IP is pingable for /32 subnets
    sample use:
       reformat_scireg.py -i scireg.json -o scireg.new-format.json -c test.csv

Obsolete, but keep around for now:
  - scireg2mmdb.py : replaced by scireg2mmdb.go
  - resourcedb-make-mmdb.pl
  - mmdb_lookup.py
  - scireg-csv2json.py
  - scireg-single-csv2json.py


