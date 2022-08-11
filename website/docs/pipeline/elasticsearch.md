---
id: elastic
title: Elasticsearch
sidebar_label: Elasticsearch
---

Flow data is ultimately saved to Elasticsearch. Following are the fields that are used/created in Logstash and that you may see returned by an elasticsearch query.

### Flow fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|start					|Jun 9, 2020 @ 17:39:53.808	|	Start time of the flow (first packet seen)|
|end					|Jun 9, 2020 @ 17:39:57.699	|End time of the flow   (last packet seen)|
|meta.id			|a17c4f0542...  |Id of the flow (hash of 5-tuple + Sensor name)|
|es_doc_id			|4f46bef884...	|Hash of meta.id and start time. May be used as doc id in ES to prevent duplicates, but see Notes elsewhere.|
|meta.flow_type			|sflow							|'sflow', 'netflow', or 'tstat'|
|meta.protocol			|tcp							|Protocol used|
|meta.sensor_id			|GEANT NY to Paris |Assigned sensor name |
|meta.sensor_group		|GEANT						|Sensor group, usually the network |
|meta.sensor_type		|Circuit  |Sensor type ('Circuit', 'Regional Network', etc) |
|meta.country_scope		|International |'Domestic', 'International', or 'Mixed', depending on countries of src and dst (Domestic = src and dst in USA)|
|meta.is_network_testing	|no	|'yes' if discipline is 'CS.Network Testing and Monitoring' or port is one used for PerfSonar: 5001, 5101, or 5201|

### Source Fields (Destination Fields similarly with "dst")

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|meta.src_ip			|171.64.68.x		    |deidentified IP address|
|meta.src_port			|80						|port used                     |
|meta.src_asn			|32						|Source ASN from the flow header or, in some cases, the ANS of the IP from the MaxMind GeoIP ASN database|
|meta.src_organization	|Stanford University	|	organization that owns the AS from the CAIDA ASN-Organization database 
|meta.src_location.lat	|	37.423				|	latitude of the IP from the MaxMind GeoIP City database|
|meta.src_location.lon	|-122.164				|	longitude of the IP from the MaxMind GeoIP City database|
|meta.src_country_name	|United States			|	country of the IP from the MaxMind GeoIP City database|
|meta.src_continent		|North America			|	continent of the IP the MaxMind GeoIP City database|
|meta.src_ifindex			|166						|the index of the interface the flow came into|

### Source Science Registry Fields  (Destination Fields similarly with "dst")
The [Science Registry](https://scienceregistry.netsage.global/rdb/) stores human-curated information about various "resources". Resources are sources and destinations of flows.

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|meta.scireg.src.discipline	|MPS.Physics.High Energy			|The science discipline that uses the resource (ie IP). Note that  not the src MAY not have the same discipline as the dst. |
|meta.scireg.src.role		|Storage						|Role that the host plays |
|meta.scireg.src.org_name	|Boston University (BU)			|The organization the manages and/or uses the resource, as listed in the Science Registry|
|meta.scireg.src.org_abbr	|Boston U						|A shorter name for the organization. May not be the official abbreviation.|
|meta.scireg.src.resource	|BU - ATLAS				|Descriptive resource name from SciReg |
|meta.scireg.src.resource_abbr	 |  						|Resource abbreviation (if any)|
|meta.scireg.src.project_names	|ATLAS 					|"Project(s)" that the resource is part of|
|meta.scireg.src.latitude	|37.4178						|Resource's latitude, as listed in the Science Registry|
|meta.scireg.src.longitude	|-122.178						|Resource's longitude, as listed in the Science Registry|

### Source "Preferred" Fields (Destination Fields similarly with "dst")

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|meta.src_preferred_org		|Stanford University			|If the IP was found in the Science Registry, this is the SciReg organization, otherwise it is the CAIDA organization|
|meta.src_preferred_location.lat	|37.417800					| Science Registry value if available, otherwise the MaxMind City DB value|
|meta.src_preferred_location.lon	|-122.172000i	|  Science Registry value if available, otherwise the MaxMind City DB value  |

### Value Fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|values.num_bits			|939, 458, 560					|Sum of the number of bits in the (stitched) flow|
|values.num_packets		|77, 824						|Sum of the number of packets in the (stitched) flows|
|values.duration			|3.891						|Calculated as end minus start.|
|values.bits_per_second	|241, 443, 988					|Calculated as num_bits divided by duration |
|values.packets_per_second	|20, 001						|Calculated as num_packets divided by duration|

### Tstat Value Fields

|name                   |example                |
|-----------------------|-----------------------|
|values.tcp_cwin_max	|1549681						|
|values.tcp_cwin_min	|17|
|values.tcp_initial_cwin|313|
|values.tcp_max_seg_size|64313|
|values.tcp_min_seg_size|17|
|values.tcp_mss		|8960|
|values.tcp_out_seq_pkts|0|
|values.tcp_pkts_dup	|0|
|values.tcp_pkts_fc	|0|
|values.tcp_pkts_fs	|0|
|values.tcp_pkts_reor	|0|
|values.tcp_pkts_rto	|0|
|values.tcp_pkts_unfs	|0|
|values.tcp_pkts_unk	|2|
|values.tcp_pkts_unrto	|0|
|values.tcp_rexmit_bytes	|1678|
|values.tcp_rexmit_pkts	|2|
|values.tcp_rtt_avg		|0.044|
|values.tcp_rtt_max		|39.527|
|values.tcp_rtt_min		|0.001|
|values.tcp_rtt_std		|0.276|
|values.tcp_sack_cnt	|	1|
|values.tcp_win_max		|1549681|
|values.tcp_win_min		|17|
|values.tcp_window_scale	|13|

### Developer Fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|@pipeline_ver			|1.2.11				| Version number of the pipeline used to process this flow |
|@ingest_time			|Jun 9, 2020 @ 10:03:20.700	| The time the flow entered the logstash pipeline |
|@timestamp			|Jun 9, 2020 @ 18:03:21.703	|The time the flow entered the logstash pipeline for tstat flows, or the time stitching finished and the event exited the aggregation filter for other flows.|
|@exit_time			|Jun 9, 2020 @ 18:03:25.369	|The time the flow exited the pipeline |
|@processing_time		|688.31						|@exit_time minus @ingest_time. Useful for seeing how long stitching took. |
|@sampling_corrected    |yes |'yes' if sampling corrections have been done; 'no' otherwise, eg, for netflows before a template has been seen that includes the sampling rate. |
|stitched_flows			|13				|Number of flows that came into logstash that were stitched together to make this final one. 1 if no flows were stitched together. 0 for tstat flows, which are never stitched. |
|tags	|maxmind src asn	|Various info and error messages|
|trial	| 5	|Can be set in 40-aggregation.conf if desired|

### Elasticsearch Fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|_index                 | om-ns-netsage-2020.06.14 | name of the index ("database table")  |
|_type    		        |_doc					|	set by ES                 |
|_id    		        |HRkcm3IByJ9fEnbnCpaY	|	elasticsearch document id. |
|_score    		        |1						 |set by ES query             |
|@version               |1				         |		set by ES             |

