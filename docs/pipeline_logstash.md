---
id: pipeline_logstash
title: Pipeline Logstash
sidebar_label: Logstash
---

# Logstash

These Logstash config files are in /etc/logstash/conf.d/

## Logstash Procedures 

The following steps are defined for logstash:

### 01-inputs.conf 

reads flows from wherever the user wants to get data; in our case, from the netsage_deidentifer_raw rabbit queue.

### 10-preliminaries.conf

drops flows to or from private IP addresses; 	
adds @injest_time; 
converts any timestamps in milliseconds to seconds; 
drops events with timestamps more than a year in the past or (10 sec) in the future; 
does some data type conversions

### 20-add_id.conf

adds a unique id based on the 5-tuple (src and dst ips and ports, and protocol) plus the sensor name. This ends up being called meta.id.
(30-xxx.conf is not used yet)

### 40-aggregation.conf

stitches together flows from different nfcapd files into longer flows, matching them up by meta.id and using a specified inactivity_timeout to decide when to start a new flow.

Notes: By default, 5-minute nfcapd files are assumed, and if less than 10.5 min have passed between the start of the current flow and the start of the last matching one, stitch the two together.

Your logstash pipeline can have only 1 worker or aggregation is not going to work! 

### 50-geoip-tagging.conf 

if the destination IP is in the multicast range, sets the destination Organization, Country, and Continent to "Multicast"; 
queries the MaxMind GeoLite2-ASN database by IP to get src and dst Organizations (note that these are the organizations associated with the ASN); 
if the ASN in the flow header differs from that which MaxMind gives, the flow header's value is saved [we need to not do this if it's a private ASN]; 
queries the MaxMind GeoLite2-City database by IP to get src and dst Countries, Continents, Latitudes, and Longitudes. 

### 55-member-orgs.conf

[this part is commented out right now: if a src or dst ASN matches a certain value, search only the corresponding lookup table.]
Search lookup tables by IP to obtain member or customer organization names and overwrite the GeoIP ASN Organization where applicable.
This allows us to have entities which don't own their own ASs be listed as the src or dst Organization.

**Notes**: Lookup tables are not stored in github.

### 60-scireg-tagging-fakegeoip.conf

uses a fake geoip database containing Science Registry information to add, for src and dst, science discipline and role, science registry organization and location, etc; 
removes scireg fields we don't actually need to save to elasticsearch.

**Notes**: The science registry fake geoip database can be downloaded from scienceregistry.grnoc.iu.edu via a cron job. 

### 65-preferred-location-org.conf

copies science registry organization and/or location values, if they exist, to the preferred_organization and/or perferred_location fields.

### 70-deidentify.conf 

replaces the last octet of IPv4 addresses and the last 4 hextets of IPv6 addresses with x's in order to deidentify them. 

### 80-privatize.org.conf

removes information about Australian organizations (or, with modification, any organization that has privacy rules that require us not to identify them).
If the ASN is one listed, completely replaces the IP with x's, sets the location to central Autralia, sets all organizations to "AARNet", removes all Projects.

### 90-additional-fields.conf

sets additional quick and easy fields. The first 2 use lookup files based on regexes.  Currently we have:
sensor_group  = TACC, AMPATH, etc
sensor_type    = Circuit, Archive, Exchange Point, or Regional Network 
country_scope = Domestic, International, or Mixed

### 95-cleanup.conf

does small misc. tasks at the end like rename, remove, or convert fields

### 99-outputs.conf -

adds @exit_time and @processing_time, 
sends results to whereever the user wants them to go. In our case, it sends them to the netsage_archive_input queue (or netsage_ilight_input, etc) on netsage-elk1.grnoc.iu.edu. 

### Final Stage 

In our case, OmniSOC manages the last stage. Their logstash reads flows from the netsage_archive_input queue and sends it into elasticsearch. The indices are named like om-ns-netsage-YYYY.mm.dd-* (or om-ns-ilight-*, etc).  

This can be easily replicated with the following configuration though you'll need one for each feed/index.

Naturally the hosts for rabbit and elastic will need to be updated accordingly.

```
input {
  rabbitmq {
    host => 'localhost'
    user => 'guest'
    password => "${rabbitmq_pass}"
    exchange => 'netsage.direct'
    key =>   XXXXXXX'
    queue => 'netsage'
    durable => true
    subscription_retry_interval_seconds => 5
    connection_timeout => 10000
  }
}
filter {
  if [@metadata][rabbitmq_properties][timestamp] {
    date {
      match => ["[@metadata][rabbitmq_properties][timestamp]", "UNIX"]
    }
  }
}

output {
    elasticsearch {
      hosts => [
          "https://CHANGEME1",
          "https://CHANGEME2"
      ]
      user => "logstash"
      password => "${logstash_elasticsearch_password}"
      cacert => "/etc/logstash/ca.crt"
      index => "om-ns-netsage"
      template_overwrite => true
      failure_type_logging_whitelist => []
      action => index
      #ssl_certificate_verification => false
    }
}
```

Once the data is published in elastic, you can use the [grafana dashboard](https://github.com/netsage-project/netsage-grafana-configs) to visualize the data.


## Elasticsearch Fields

### ES fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|_index                 | om-ns-netsage-2020.06.| equivalent to an sql table  |
|_type    		        |_doc					|	set by ES                 |
|_id    		        |HRkcm3IByJ9fEnbnCpaY	|	document id, set by ES    |
|_score    		        |1						 |set by ES query             |
|@version               |1				         |		set by ES             |

### Developer fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|type				    | flow					|	Always "flow" for us. Other types may be "macy", etc. |
|@injest_time			|2020-06-09T21:51:57.059Z	|	Essentially time the flow went into the logstash pipeline (10-preliminaries.conf for tstat flows) or the time stitching of the flow commenced (40-aggregation.conf for others)|
|@timestamp			|Jun 9, 2020 @ 18:03:21.703	|The time the flow went into the logstash pipeline for tstat flows, or the time stitching finished and the event was pushed for other flows.|
|@exit_time			|Jun 9, 2020 @ 18:03:25.369	|The time the flow exited the pipeline (99-outputs.conf)|
|@processing_time		|688.31						|@exit_time minus @injest_time. Useful for seeing how long stitching took. |
|stitched_flows			|1							|Number of flows stitched together to make this final one. 0 for tstat flows, which are always complete. 1 if no flows were stitched together.|

### Flow fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|start					|Jun 9, 2020 @ 17:39:53.808	|	Start time of the flow (first packet seen)|
|end					|Jun 9, 2020 @ 17:39:57.699	|End time of the flow   (last packet seen)|
|meta.protocol			|tcp							|Protocol used|
|meta.id			| a17c4f05420d7ded9eb151ccd293a633 ff226d1752b24e0f4139a87a8b26d779    |Assigned flow id|
|meta.flow_type			|sflow							|Sflow, Netflow, or Tstat|
|meta.sensor_id			| snvl2-pw-sw-1-mgmt-2.cenic.net|Sensor name (set in importer config, may not always be a hostname) |
|meta.sensor_group		|CENIC						|Assigned sensor group |
|meta.sensor_type		|Regional Network				|Assigned sensor type |
|meta.country_scope		|Domestic						|Domestic, International, or Mixed, depending on countries of src and dst|

### Source Fields (Destination Fields similarly)

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|meta.src_ip			|171.64.68.x		    |		deidentified IP address|
|meta.src_port			|80						|port used                     |
|meta.src_asn			|32						|ASN of the IP from geoip ASN database or the ASN from the flow header |
|meta.src_location.lat	|	37.423				|	latitude of IP from geoip database|
|meta.src_location.lon	|-122.164				|	longitude of IP from geoip database|
|meta.src_country_name	|United States			|	country of IP from geoip database|
|meta.src_continent		|North America			|	continent of IP from geoip database|
|meta.src_organization	|Stanford University	|		organization that owns the AS of the IP from geoip ASN database 

### Source Science Registry Fields  (Destination Fields similarly)

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|meta.scireg.src.resource	|Stanford - ImageNet				|Resource name from SciReg |
|meta.scireg.src.resource_abbr	 | - 						|Resource abbreviation (if any)|
|meta.scireg.src.discipline	|CS. Intelligent Systems			|The science discipline that uses the resource (ie host). Note that  not the src MAY not have the same discipline as the dst. |
|meta.scireg.src.role		|Storage						|Role that the host plays |
|meta.scireg.src.org_name	|Stanford University			|The organization the manages and/or uses the resource, as listed in the Science Registry|
|meta.scireg.src.org_abbr	|Stanford						|A shorter name for the organization. May not be the official abbreviation.|
|meta.scireg.src.projects	| . 					|Can be an array of projects [we may change this field name soon]|
|meta.scireg.src.latitude	|37.4178						|Resource's location, as listed in the Science Registry|
|meta.scireg.src.longitude	|-122.172 |  |

### "Preferred" fields

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|meta.src_preferred_org		|Stanford University			|If the IP was found in the Science Registry, these are the SciReg values.|
|meta.src_preferred_location.lat	|37.417800					|Otherwise, they are the geoip values.|
|meta.src_preferred_location.lon	|-122.172000 |   |

### Values

|name                   |example                |description                  |
|-----------------------|-----------------------|-----------------------------|
|values.num_bits			|939, 458, 560					|Sum of the number of bits in all the stitched flows|
|values.num_packets		|77, 824						|Sum of the number of packets in all the stitched flows|
|values.duration			|3.891						|Calculated as end minus start|
|values.bits_per_second	|241, 443, 988					|Calculated as num_bits divided by duration |
|values.packets_per_second	|20, 001						|Calculated as num_packets divided by duration|

### Tstat Values

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
