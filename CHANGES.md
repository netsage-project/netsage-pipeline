------------------------------------------------------
## GRNOC NetSage Deidentfier 1.2.6 -- 
------------------------------------------------------
Features:
  * Split input and output options into their own .conf files for easy enable/disable. Unused ones have .disabled extension. 
  * Docker changes to allow more than one sflow/netflow sensor (default is 1 of each but user can edit shared file to set it up how they want)
  * Split geoip-tagging config into 2 parts to separately get location and ASNs -- new 45-geoip-tagging.conf and 50-asn.conf.
  * If the flow's original asn is private, 0, etc, try getting an asn from the maxmind ASN db by IP. If one is found, add tag "maxmind src/dst asn"
  * Get organizations from CAIDA csv file -- added 53-caida-org.conf 
  * If lat/lon are unknown, don't set the fields at all. Set country and continent to Unknown.
  * If a public asn is not found, set asn to -1 (instead of 0)
  * If the org cannot be determined, set it to "Unknown"
  * Convert the common variations of AARNET org names to "Australian Academic and Research Network (AARNet)", whether redacted or not. (caida changed what they used between April and July)
  * If dst is Multicast, set no country_scope. 
  * Don't save empty project fields (but keeping original project field for now for grafana)
  * Moved @exit_time and @processing_time to 98-post-process.conf
  * Added replay script given a valid input file.
  * Started to add Automated Ruby Unit tests. (Next major commit will include more concrete examples)
  * changed some dir names
  * Added sox and fixed gpn and tacc in sensor_groups and sensor_types dictionaries

------------------------------------------------------
## GRNOC NetSage Deidentfier 1.2.5 -- Jul 15 2020     
------------------------------------------------------
SCTASK0055523 (release)
Features:
  * Added new field is_network_testing
  * Moved project info to new fields meta.scireg.src/dst.project_names and project_abbrs
  * Uncommented prefiltering by ASN for member-org lists
  * In FlowFilter.pm, skip flows with a missing ifindex.
  * Enabled Docker releases based on a Release Tag.
  * Other changes to comments, misc minor things.
  * Added some documentation.
  * Added a logstash restart script in /usr/bin/ to be run by cron. Will make sure logstash is stopped before starting.

Bugs:
  * Will not save the flow-asn if it is in the private range
  * If there is no ASN from flow header or geoip, set it to 0
  * Fixed 80-privatize-org.conf to redact if COUNTRY is Australia
  * Preferred org and location need to be added after privatize, so renamed it from 65 to 88
  * Added full paths to logstash ruby and support files

------------------------------------------------------
## GRNOC NetSage Deidentfier 1.2.4 -- May 25 2020     
------------------------------------------------------
SCTASK0052575 (release)
Features:
  * Various Docker-related updates and fixes
  * Added automatic docusaurus-based documentation
  * Updated importer to handle protocols returned as names rather than numbers
  * Renumbered logstash config files
  * Added new fields in 90-additional-fields.conf: 
                      sensor_group (TACC, CENIC, I-Light, etc),
                      sensor_type  (circuit, exchange-point, etc),
                      country_scope (Domestic, International, Mixed)
  * Added 55-member-orgs.conf - replaces Organization with member or customer name according to netblock-entity mapping files
        for members/customers without their own ASNs.  (SCTASK0052380)
  * Added 65-preferred-location-org.conf - prefer science registry value, fall back to geoip value. New fields (SCTASK0052382)
                      src/dst_preferred_location.lat, 
                      src/dst_preferred_location.lon,
		      src/dst_preferred_org
  * Various other small changes, reorganization, and fixes.

------------------------------------------------------
## GRNOC NetSage Deidentfier 1.2.3 -- Apr 1 2020     
------------------------------------------------------
SCTASK0047629
Features:
  * Added docker support 
  * Changed the logstash requirement to be >= 7.4.2 
  * Added --sharedconfig to startup commands for importer and flow_filter in init.d and systemctl files
  * Added more info to logstash error tags and added filter ids. Will now not add an error-tag if scireg lookup fails.
  * If the src or dst IP is in a private range, the flow will now be dropped.
  * Will now drop flows that have flow start or end time > 1 year in the past or > 10 s in the future.
  * Renamed 02-convert.conf to 02-preliminaries.conf (added the checks for private addresses and strange dates there)
  * For Australian flows, will now only redact info if the the continent is Australia (in addition to the ASN being in the list).
  * Removed unneeded science registry fields from what is saved to elasticsearch.
  * Removed other unnecessary fields from configs and elasticsearch, eg, timestamps, country codes.
  * For Multicast destinations, the organization, country, and continent will now be "Multicast". No lat/lon for dst.
  * If the ASN in the event (from the flow header) is missing, 0, 4294967295, or 23456, it will be overwritten by whatever the 
    GeoIP ASN db gives (if the IP is in the db), otherwise, the ASN from the flow header will be preserved. 
    If the saved flow-ASN differs from the geoip-ASN, a tag is added. NOTE that the organization and location will match the geoip-ASN!
  * If an IP is found in the geoip dbs but there is no organization, country, or continent, the missing fields will be set to "Unknown".
  * Various other small changes, reorganization, and fixes.

Bugs:
  * In NetflowImporter.pm, made it skip empty nfcapd files since these were causing occasional crashes
  * In the ipv6 anonymizer script, made a change to handle addresses ending in ::  


------------------------------------------------------
## GRNOC NetSage Deidentfier 1.2.2 -- Jan 22 2020     
------------------------------------------------------
Features:
  * SCTASK0030490  Added redactor/privatize-org logstash config
  * SCTASK0041528  Tested and made changes to logstash stitching  (and added old stitcher files to a dir in git for reference)
  * Made various tweaks to other logstash configs
  * Required logstash = 7.4.2 (to include changes John Ratliff contributed to aggregate plugin)
  * Added a cron file to restart logstash  
  * Renamed some logstash config files *.conf.template. Upgrades will replace these but not the user-edited *.conf files.

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

