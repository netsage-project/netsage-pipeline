## GRNOC NetSage Deidentifier 0.0.4 -- ?????????  2016

Bugs:
 * ISSUE=1879 PROJ=160 Fixed netflow-importer-daemon so it goes into the background when started.
                       Create /var/cache/netsage/ on install
                       Fixed issues that prevented pipeline processes from stopping correctly
                       Fixed an issue where the netflow importer would die (now it logs an error message)

Features:
 * ISSUE=1879 PROJ=160 Changed log messages to include the process name and use different formatting. 
                       Made it so that when pipeline processes are started up, they quit immediately 
                       if they cannot connect to rabbit. Added a reminder to the user to check for process.
 * ISSUE=2210 PROJ=160 Added the ability to archive flow data to .jsonl files, as well as import these files
 * ISSUE=2157 PROJ=160 Add sensor ID and sensor type to netflow importer
 
## GRNOC NetSage Deidentifier 0.0.3 -- Wed Aug 24 2016

Features:
 * ISSUE=1359 PROJ=160 Create netflow input module

Bugs:
 * ISSUE=1643 PROJ=160 Improve logging in pipeline

## GRNOC NetSage Deidentifier 0.0.2 -- Mon July 25 2016

Features:
 * ISSUE=635 PROJ=160 Added flow stitching functionality. 

## GRNOC NetSage Deidentifier 0.0.1 -- Fri April 1 2016

Features:
 * ISSUE=543 PROJ=160 Initial implementation of NetSage flow deidentification pipeline. 

