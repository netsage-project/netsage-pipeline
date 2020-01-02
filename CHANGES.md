------------------------------------------------------
## GRNOC NetSage Deidentfier 1.3.0 -- Jan 2 2020     
------------------------------------------------------
Features:
  * SCTASK0030490  Added redactor/privatize-org logstash config
  * SCTASK0041528  Made fixes to logstash stitching  (and added old stitcher files to a dir in git for reference)
  * Made various tweaks to other logstash configs
  * Required logstash >= 7.4.1 (to include changes John contributed to aggregate plugin)
  * Added a cron file to restart logstash  (note that restarting logstash will break aggregation currently!)

------------------------------------------------------
## GRNOC NetSage Deidentfier 1.2 1 -- Fri May 31 2019
------------------------------------------------------
Bugs:
  * Fixed flow duration calculation, required logstash >= 6.2.4, moved RawDataImporter to util/. (SCTASK0031312)

------------------------------------------------------
## GRNOC NetSage Deidentfier 1.2.0 -- Fri May 17 2019
------------------------------------------------------
SCTASK0028272 (and SCTASK0023793)

Features: 
  * Added option -6 to nfdump command to get full ipv6 addresses
  * Added logstash stitching; removed old pipeline stitcher and cacher, also archiver.
  * Added the use of the logstash keystore for usernames and passwords in logstash config files
  * Modified/cleaned up config files, comments, etc.

Bugs:
  * Fixed file permissions in spec file
  * Added installation of systemd files for Centos7 which was previously missing

------------------------------------------------------
## GRNOC NetSage Deidentfier 1.1.0 -- Mon Mar 29 2019
------------------------------------------------------
Features (SCTASK0025331):
  * Added logstash configs that have replaced some old-pipeline components - input, geoip, scireg, deidentify, cleanup, output
  * Removed unneeded old-pipeline components: deidentifer, tagger, scireg_tagger, finished_flow_mover
  * Edited spec file, etc. to account for changes, moved some files around

Bugs:
  Other commits (ticket numbers unknown) -
  * 02/27/18 - Fixed a subtle bug regarding IPC::ShareLite
  * 07/05/18 - If a message from a rabbit queue is not an array, make it into one
  * 07/20/18 - Open file for archiving with utf-8 encoding in order to work right with science registry info
  * 10/04/18 - SA should be South America, not South Africa

------------------------------------------------------
## GRNOC NetSage Deidentifier 1.0.3 --  Fri Feb 23 2018
------------------------------------------------------
Features:
 * ISSUE= 6365 PROJ=160 Tag flows based on metadata from the science registry

------------------------------------------------------
## GRNOC NetSage Deidentifier 1.0.2 --  Wed Nov 8 2017
------------------------------------------------------
Bugs:
 * ISSUE=5575 PROJ=160 Fix issue acking/rejecting bad input data

------------------------------------------------------
## GRNOC NetSage Deidentifier 1.0.1 --  Wed Oct 25 2017
------------------------------------------------------
Features:
 * ISSUE=3754 PROJ=160 Extend shared config to archiver and flow mover

------------------------------------------------------
## GRNOC NetSage Deidentifier 1.0.0 --  Wed Oct 10 2017
------------------------------------------------------
Features:
 * ISSUE=3754 PROJ=160 Support for importing data from multiple routers on one host
 * ISSUE=3754 PROJ=160 Add shared config capability
 * ISSUE=4840 PROJ=160 filtered flow collection capability; add ifindex metadata

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.1.1 --  Wed Aug 22 2017
------------------------------------------------------
Features:
 * ISSUE=4840 PROJ=160 Additional pipeline stage for filtering flow records before processing
 * ISSUE=4693 PROJ=160 Add systemd unit files for EL7
 * ISSUE=4693 PROJ=160 Improvements to EL6 startup scripts
 * ISSUE=4693 PROJ=160 Make the daemons retry RabbitMQ connections when started

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.1.0 --  Tue Jun 27 2017
------------------------------------------------------
Features:
 * ISSUE=3753 PROJ=160 Ability to cull imported nfdump files after a specified timeperiod

Bugs:
 * ISSUE=4167 PROJ=160 Remove use of a buggy library that was causing netflow importer to crash

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.9 --  Wed Jun 21 2017
------------------------------------------------------
Features:
 * ISSUE=4271 PROJ=160 Add instance id tag
 * ISSUE=4441 PROJ=160 Make IPC key configurable

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.8 --  Tue Jun 20 2017
------------------------------------------------------
Features:
 * ISSUE=4171 PROJ=160 Add min byte threshold for flows

Bugs:
 * ISSUE=4167 PROJ=160 Potential fix for netflow importer crashes

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.7 -- Fri Apr 21 2017
------------------------------------------------------
Features:
 * ISSUE=3752 PROJ=160 Add support for "sflow" flow type
 * ISSUE=3553 PROJ=160 Pipeline support for CentOS 7

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.6 -- Wed Apr 5 2017
------------------------------------------------------
Features:
 * ISSUE=2996 PROJ=160 Added tagging of Continent

Bugs:
 * ISSUE=2505 PROJ=160 Fixed a crash in the netflow importer

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.5-2 -- Fri Jan 6 2017
------------------------------------------------------
Features:
 * ISSUE=2863 PROJ=160 Made nfdump path configurable
 * ISSUE=2863 PROJ=160 Improved logging

Bugs:
 * ISSUE=2505 PROJ=160 Drop redundant netflow src/dst ASN values
 * ISSUE=2507 PROJ=160 Handling of protocol values - use names instead of numbers
 * ISSUE=2863 PROJ=160 Fix an incorrect commandline parameter that was being sent to nfdump
 * ISSUE=2863 PROJ=160 Fix export-tsds and null/empty strings for importer

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.4 -- Mon Nov 7 2016
------------------------------------------------------
Features:
 * ISSUE=2157 PROJ=160 Add new required fields: sensor ID and sensor type, to netflow importer
 * ISSUE=1879 PROJ=160 Changed log messages to include the process name and use different formatting. 
                       Made it so that when pipeline processes are started up, they quit immediately 
                       if they cannot connect to rabbit. Added a reminder to the user to check for process.
 * ISSUE=2210 PROJ=160 Added the ability to archive flow data to .jsonl files, as well as import these files. This also includes support for rabbit exchanges and durability parameters
 * ISSUE=2455 PROJ=160 Ability to import/export data to/from TSDS

Bugs:
 * ISSUE=1879 PROJ=160 Fixed netflow-importer-daemon so it goes into the background when started.
                       Create /var/cache/netsage/ on install
                       Fixed issues that prevented pipeline processes from stopping correctly
                       Fixed an issue where the netflow importer would die (now it logs an error message)
 
------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.3 -- Wed Aug 24 2016
------------------------------------------------------
Features:
 * ISSUE=1359 PROJ=160 Create netflow input module

Bugs:
 * ISSUE=1643 PROJ=160 Improve logging in pipeline

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.2 -- Mon July 25 2016
------------------------------------------------------
Features:
 * ISSUE=635 PROJ=160 Added flow stitching functionality. 

------------------------------------------------------
## GRNOC NetSage Deidentifier 0.0.1 -- Fri April 1 2016
------------------------------------------------------
Features:
 * ISSUE=543 PROJ=160 Initial implementation of NetSage flow deidentification pipeline. 

