## GRNOC NetSave Deidentifier 0.0.4 -- ?????????  2016

Bugs:
 * ISSUE=1879 PROJ=160 Fixed netflow-importer-daemon so it goes into the background when started.
                       Added /var/cache/netsage/ creation to the .spec file.
                       Got "sudo service xxx stop" to work for all the pipeline processes.
                       Changed a "die" to an error log message in netflow importer.

Features:
 * ISSUE=1879 PROJ=160 Changed log messages to include the process name and use different formatting. 
                       Made it so that when pipeline processes are started up, they quit immediately 
                       if they cannot connect to rabbit. Added a reminder to the user to check for process.
                       Changed task_types to "no_input_queue" and "no_output_queue".
 
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

