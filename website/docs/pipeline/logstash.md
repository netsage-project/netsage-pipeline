---
id: logstash
title: Logstash Pipeline
sidebar_label: Logstash
---

The Logstash portion of the Netsage Pipeline reads in flows from a RabbitMQ queue, performs various transformations and adds additional information to them, then sends them to a location specified in the output logstash config, eventually ending up in an Elasticsearch instance. 

Logstash config files invoke various logstash "filters" and actions. These conf files are located in /etc/logstash/conf.d/. See below for a brief description of what each does and check the files for comments.

Notes: 
 - All \*.conf files in conf.d/ are executed in alphabetical order, as if they were one huge file. Those ending in .disabled will not be executed (assuming 'path.config: "/etc/logstash/conf.d/*.conf"' in /etc/logstash/pipelines.yml).
 - If actions in a particular .conf file are not needed in your particular case, they can be removed or the file disabled, but check carefully for effects on downstream configs.
 - MaxMind, CAIDA, and Science Registry database files required by the geoip and aggregate filters are downloaded from scienceregistry.netsage.global via cron jobs weekly or daily. (MaxMind data can change weekly, CAIDA quarterly, Science Registry information randomly.) **NOTE that new versions won't be used in the pipeline until logstash is restarted.** There is a cron file to do this also, though it's not running in Docker deployments. Similarly for other support files, eg, those used in 90-additional-fields.conf.
 - Lookup tables for 55-member-orgs.conf that we have compiled are available from sciencregistry.grnoc.iu.edu. See the cron files provided. These will not be updated often, so you may run the cron jobs or not. You will need to provide lists for other networks yourself or ask us.

## Logstash Sequence

### 01-input-rabbit.conf

Reads flows from a rabbitmq queue. (The ".disabled" extenstion can be removed from other 01-input configs available in conf.d/ to get flows from other sources.)

### 10-preliminaries.conf

Drops flows to or from private IP addresses;
converts any timestamps in milliseconds to seconds;
drops events with timestamps more than a year in the past or (10 sec) in the future;
does some data type conversions;
adds @ingest_time (this is mainly for developers).

### 15-sensor-specific-changes.conf

Makes any changes to fields needed for specific sensors. This config currently provides 1) the ability to drop all flows that do not use interfaces (ifindexes) in a specfied list, 2) the ability to change the sensor name for flows from a specified sensor which go through a certain interface, and 3) the ability to apply a sampling rate correction manually for named sensors. You may edit the file in a bare-metal installation and specify everything explicitly (upgrades will not overwrite this config) or you may use the environment file specified in the systemd unit file. For Docker installations, use the .env file to specifiy the parameters. By default, this config will do nothing since the flags will be set to False.

### 20-add_id.conf

Adds a unique id (evenutally called meta.id) which is a hash of the 5-tuple of the flow (src and dst ips and ports, and protocol) plus the sensor name. This id is used for aggregating (stitching) in the next step. 

### 40-aggregation.conf

Stitches together flows from different nfcapd files into longer flows, matching them up by meta.id and using a specified inactivity_timeout to decide when to start a new flow.

Notes: 
 - By default, 5-minute nfcapd files are assumed and the inactivity_timeout is set to 10.5 minutes. If more than 10.5 min have passed between the start of the current flow and the start of the last matching one, do not stitch them together.
 - If your nfcapd files are written every 15 minutes, change the inactivity_timeout to at least 16 minutes.
 - There is another "timeout" setting which is basically the maximum duration of a stitched flow (default: 24 hr).
 - When logstash shuts down, any flows "in the aggregator" will be written out to aggregate_maps_path (default: /tmp/logstash-aggregation-maps). The file is then read back in when logstash is restarted so aggregation can continue. 
 - Your logstash pipeline can have only 1 worker or aggregation is not going to work! This is set in the logstash config file.
 - Tstat flows come in already complete, so no aggregation is done on those flows.

### 45-geoip-tagging.conf

Queries the MaxMind GeoLite2-City database by IP to get src and dst Countries, Continents, Latitudes, and Longitudes;
if the destination IP is in the multicast range, sets the destination Organization, Country, and Continent to "Multicast".

*This product includes GeoLite2 data created by MaxMind, available from [www.maxmind.com](http://www.maxmind.com).*

### 50-asn.conf

Normally with sflow and netflow, flows come in with source and destination ASNs.  If there is no ASN in the input event; or the input ASN is 0, 4294967295, or 23456, or it is a private ASN, tries to get an ASN by IP from the MaxMind ASN database.
Sets ASN to -1 if it is unavailable for any reason.

### 53-caida-org.conf

Uses the current source and destination ASNs to get organization names from the prepared CAIDA ASN-to-Organization lookup file.

*This product uses a lookup table constructed from the CAIDA AS Organizations Dataset - see [www.caida.org](http://www.caida.org/data/as-organizations).* 

### 55-member-orgs.conf

Searches any provided lookup tables by IP to obtain member or customer organization names and overwrite the Organization determined previously.
This allows entities which don't own their own ASs to be listed as the src or dst Organization.

Note: These lookup tables are not stored in github, but an example is provided to show the layout and tables we have can be downloaded via a cron job.

### 60-scireg-tagging-fakegeoip.conf

Uses a fake geoip database containing [Science Registry](http://scienceregistry.grnoc.iu.edu) information to tag the flows with source and destination science disciplines and roles, organizations and locations, etc;
removes Registry fields we don't need to save to elasticsearch.

Notes: 
 - The [Science Registry](https://scienceregistry.netsage.global/rdb/) stores human-curated information about various "resources". Resources are sources and destinations of flows.
 - The Science Registry "fake geoip database" is updated weekly and can be downloaded via wget in a cron job (provided in the installation).

### 70-deidentify.conf

Replaces the last octet of IPv4 addresses and the last 4 hextets of IPv6 addresses with x's in order to deidentify them.

### 80-privatize.org.conf

Removes information about Australian organizations (or, with modification, any country that has privacy rules that require us not to identify organizations).
If the ASN is one of those listed, completely replaces the IP with x's, sets the location to central Autralia, sets all organizations to "AARNet", removes all Projects.

### 88-preferred-location-org.conf

Copies Science Registry organization and location values, if they exist, to the meta.preferred_organization and meta.preferred_location fields. If there are no Science Registry values, the organizations and locations from the CAIDA and MaxMind lookups, respectively, are saved to those fields.

### 90-additional-fields.conf

Sets additional quick and easy fields.  Supporting mapping or ruby files are used - see support/ and ruby/ in conf.d/. Currently we have (for Netsage's use):
 - sensor_group  = TACC, AMPATH, etc.  (based on matching sensor names to regexes)
 - sensor_type   = Circuit, Archive, Exchange Point, or Regional Network  (based on matching sensor names to regexes)
 - country_scope = Domestic, International, or Mixed  (based on src and dst countries and possibly continents, where Domestic = US, Puerto Rico, or Guam)
 - is_network_testing = yes, no  (yes if discipline from the science registry is 'CS.Network Testing and Monitoring' or port = 5001, 5101, or 5201)
 - es_doc_id = hash of meta.id and the start time of the flow. If this id is used as the document id in elasticsearch, flows that are mistakenly input more than once will update existing documents rather than be added as duplicates. (NOTE: due to how netflow works, use es_doc_id as the ES document id only for sflow!)

### 95-cleanup.conf

Does small misc. tasks at the end like rename, remove, or convert fields

### 98-post-process.conf

Adds @exit_time and @processing_time (these are mainly for developers)

### 99-output-rabbit.conf

Sends results to a final RabbitMQ queue. (".disabled" can be removed from other output configs to send flows to other places)

### Final Stage 

In the GlobalNOC-Netsage case, the output filter writes the flows to a network-specific RabbitMQ queue on another host and the last stage is a separate logstash pipeline on a 3rd host. The latter reads flows from the final queue using a rabbitmq input filter and sends it into elasticsearch using an elasticsearch output filter with a mapping template which sets data types for the fields. 

## Field names

The fields used/created in Logstash (and saved to Elasticsearch) are listed in the [Elasticsearch doc](elastic).


