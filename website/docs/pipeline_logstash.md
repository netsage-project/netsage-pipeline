---
id: pipeline_logstash
title: Pipeline Logstash
sidebar_label: Logstash
---

# Logstash

These Logstash config files are in /etc/logstash/conf.d/

## Logstash Sequence

The following steps are defined for logstash:

### 01-input-rabbit.conf

Reads flows from a rabbitmq queue. (".disabled" can be removed from other input configs to get flows from other sources.)

### 10-preliminaries.conf

Drops flows to or from private IP addresses;
adds @ingest_time (this is mainly for developers);
converts any timestamps in milliseconds to seconds;
drops events with timestamps more than a year in the past or (10 sec) in the future;
does some data type conversions

### 20-add_id.conf

Adds a unique id based on the 5-tuple of the flow (src and dst ips and ports, and protocol) plus the sensor name. This ends up being called meta.id.

### 40-aggregation.conf

Stitches together flows from different nfcapd files into longer flows, matching them up by meta.id and using a specified inactivity_timeout to decide when to start a new flow.

Notes: By default, 5-minute nfcapd files are assumed, and if less than 10.5 min have passed between the start of the current flow and the start of the last matching one, stitch the two together.

Your logstash pipeline can have only 1 worker or aggregation is not going to work!

### 45-geoip-tagging.conf

If the destination IP is in the multicast range, sets the destination Organization, Country, and Continent to "Multicast";
queries the MaxMind GeoLite2-City database by IP to get src and dst Countries, Continents, Latitudes, and Longitudes.

### 50-asn.conf

Normally, flows come in with source and destination ASNs.  If there is no ASN in the input event; or the input ASN is 0, 4294967295, or 23456, or it is a private ASN, try getting an ASN by IP from the MaxMind ASN database.
Sets ASN to -1 if it is unavailable for any reason.

### 53-caida-org.conf

Uses the ASN determined previously to get the organization name from the prepared CAIDA lookup file.

### 55-member-orgs.conf

Search (optional) lookup tables by IP to obtain member or customer organization names and overwrite the Organization determined previously.
This allows entities which don't own their own ASs to be listed as the src or dst Organization.

Notes: These lookup tables are not stored in github.

### 60-scireg-tagging-fakegeoip.conf

Uses a fake geoip database containing Science Registry information to tag the flows with source and destination science disciplines and roles, organizations and locations, etc;
removes scireg fields we don't need to save to elasticsearch.

Notes: The science registry fake geoip database can be downloaded from scienceregistry.grnoc.iu.edu via wget in a cron job.

### 70-deidentify.conf

Replaces the last octet of IPv4 addresses and the last 4 hextets of IPv6 addresses with x's in order to deidentify them.

### 80-privatize.org.conf

Removes information about Australian organizations (or, with modification, any country that has privacy rules that require us not to identify organizations).
If the ASN is one of those listed, completely replaces the IP with x's, sets the location to central Autralia, sets all organizations to "AARNet", removes all Projects.

### 88-preferred-location-org.conf

Copies Science Registry organization and location values, if they exist, to the preferred_organization and preferred_location fields.

### 90-additional-fields.conf

Sets additional quick and easy fields.  Currently we have:
*sensor_group  = TACC, AMPATH, etc.  (based on matching sensor names to regexes)
*sensor_type    = Circuit, Archive, Exchange Point, or Regional Network  (based on matching sensor names to regexes)
*country_scope = Domestic, International, or Mixed  (based on src and dst countries, where Domestic = US, Puerto Rico, or Guam)
*is_network_testing = yes, no  (yes if discipline = CS.Network Testing and Monitoring or port = 5001, 5101, or 5201)

### 95-cleanup.conf

Does small misc. tasks at the end like rename, remove, or convert fields

### 98-post-process.conf

Adds @exit_time and @processing_time (these are mainly for developers)

### 99-output-rabbit.conf

Sends results to a rabbitmq queue (".disabled" can be removed from other output configs to send flows to other places)

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
