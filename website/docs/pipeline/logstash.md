---
id: logstash
title: Logstash Pipeline
sidebar_label: Logstash
---

The Logstash portion of the Netsage Pipeline reads flows from a RabbitMQ queue, performs various transformations and adds additional information, then sends them to a rabbitMQ queue on a different host. Eventually the data ends up in an Elasticsearch data store.

Logstash .conf files invoke various "filters" and actions. In the bare metal installation, these conf files are located in /etc/logstash/conf.d/. In a docker installation, they are located in the conf-logstash/ directory of the git checkout of the pipeline. See below for a brief description of what each does and check the files for comments.

> - All \*.conf files in conf.d/ or conf-logstash/ are executed in alphabetical order, as if they were one huge file. Those ending in .disabled will not be executed (assuming 'path.config: "/etc/logstash/conf.d/*.conf"').
> - If you are not running a standard Netsage pipeline and actions in a particular .conf file are not needed in your particular case, they or the whole .conf file can be removed, but check carefully for downstream effects.
> - MaxMind, CAIDA, and Science Registry database files required by the geoip and aggregate filters are downloaded from scienceregistry.netsage.global via cron jobs on a weekly or daily basis. (MaxMind data can change weekly, CAIDA quarterly, Science Registry information randomly.) **NOTE that new versions won't be used in the pipeline until logstash is restarted.** There is a cron file to do this also. Similarly for other support files, eg, those used in 90-additional-fields.conf.
> - "Member organization" lists that we have stored are available to download from sciencregistry.grnoc.iu.edu. See the cron files provided. These will not be updated often. You will need to provide lists for other networks yourself or ask us. (See Docker Advanced Options.)

## Logstash Sequence

The main things done in each conf file are as follows. (Please double check the comments in the files themselves, as well, in case this documentation fails to keep up with changes.)

### 01-input-rabbit.conf

Reads flows from a rabbitmq queue. (The ".disabled" extention can be removed from other 01-input configs available in conf.d/ to get flows from other sources, probably for testing.)

### 05-translate-pmacct.conf

Renames fields provided by pmacct processes to match what the pipeline uses (from before we used pmacct). 

### 10-preliminaries.conf

Drops flows to or from private IP addresses;
converts any timestamps in milliseconds to seconds;
drops strange events with timestamps more than a year in the past or (10 sec) in the future;
sets duration and rates to 0 if duration is <= 0.002 sec (because tiny durations/few samples lead to inaccurate rates)

### 15-sensor-specific-changes.conf

Makes any changes to fields needed for specific sensors. This config currently provides 1) the ability to drop all flows that do not use interfaces (ifindexes) in a specfied list; lists can be sensor-specific, 2) the ability to change the sensor name for flows from a specified sensor which use a certain interface, 3) the ability to apply a sampling rate correction manually for named sensors, and 4) the ability to add subnet filtering for flows from specified sensors. 

You may edit the file in a bare-metal installation and specify everything explicitly (upgrades will not overwrite this config) or you may use the environment file specified in the systemd unit file. For Docker installations, use the .env file to specifiy the parameters. By default, this config will do nothing since the flags will be set to False.

### 20-add_id.conf

Adds a unique id (evenutally called meta.id) which is a hash of the 5-tuple of the flow (src and dst ips and ports, and protocol) plus the sensor name. 

### 40-aggregation.conf

Stitches incoming flows into longer flows. The inactive timeout is 6 minutes, by default. So, if the time from the start of the current flow to the start time of the last matching flow is over 6 minutes, declare the previous aggregated flow ended and start a new one with the current incoming flow. The default active timeout is 1 hour, meaning any flows over 1 hour in length will be split up into 1 hour chunks. This may require the start time to be adjusted, to cut off previous whole hours.

For sflow, aggregation uses the 5-tuple plus sensor name.
For netflow, aggregation uses the 5-tuple plus sensor name plus start time. This means that when there's a timeout at the router (default inactive timeout is usually 15 sec), the flows will stay separate. (In certain grafana dashboards, they will be added together.) Start times of incoming flows are adjusted. See comments in file.

Notes
 - When logstash shuts down, any flows "in the aggregator" will be written out to aggregate_maps_path (default: /tmp/logstash-aggregation-maps). The file is then read back in when logstash is restarted so aggregation can continue. 
 - Your logstash pipeline can have only 1 worker or aggregation is not going to work! This is set in the logstash config file.
 - Tstat flows come in already complete, so no aggregation is done on those flows.

### 41-thresholds.conf

Drops flows that are too small - under 10 MB, by default.
For flows with small durations, sets rates to 0 because sampling makes them too inaccurate.

### 45-geoip-tagging.conf

Queries the MaxMind GeoLite2-City database by IP to get src and dst Countries, Continents, Latitudes, and Longitudes;
if the destination IP is in the multicast range, sets the destination Organization, Country, and Continent to "Multicast".

*This product uses GeoLite2 data created by MaxMind, available from [www.maxmind.com](http://www.maxmind.com).*

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

Deidentfication can be skipped by using an option in the environment file.

### 80-privatize.org.conf

Removes information about Australian organizations (or, with modification, any country that has privacy rules that require us not to identify organizations).
If the ASN is one of those listed, completely replaces the IP with x's, sets the location to central Autralia, sets all organizations to "AARNet", removes all Projects.

### 88-preferred-location-org.conf

Copies Science Registry organization and location values, if they exist, to the meta.preferred_organization and meta.preferred_location fields. If there are no Science Registry values, the organizations and locations from the CAIDA and MaxMind lookups, respectively, are saved to those fields.

### 90-additional-fields.conf

Sets additional quick and easy fields.  Supporting mapping or ruby files are used - see support/ and ruby/ in conf.d/. Currently we have (for Netsage's use):
 - sensor_group  = TACC, NEAAR, I-Light, etc.  (based on matching sensor names to regexes)
 - sensor_type   = Circuit, Archive, Exchange Point, Regional Network, Facility Edge, Campus  (based on matching sensor names to regexes)
 - country_scope = Domestic, International, or Mixed  (based on src and dst countries and possibly continents, where Domestic = US, Puerto Rico, or Guam)
 - is_network_testing = yes, no  (yes if discipline from the science registry is 'CS.Network Testing and Monitoring' or if port = 5001, 5101, or 5201)
 - es_doc_id = hash of meta.id and the start time of the flow. If this id is used as the document id in elasticsearch, flows that are mistakenly input more than once will update existing documents rather than be added as duplicates. (NOTE: due to how netflow works, use es_doc_id as the ES document id only for sflow!) This id may or may not be used for the document id in Elasticsearch. It may be used for other purposes in grafana dashboards, as well.

### 95-cleanup.conf

Does small miscellaneous tasks at the end like rename, remove, or convert fields

### 98-post-process.conf

Adds @exit_time, @processing_time, and @pipeline_ver (these are mainly for developers)

### 99-output-rabbit.conf

Sends results to a final RabbitMQ queue. (".disabled" can be removed from other output configs to send flows to other places)

### Final Stage 

In the GlobalNOC-Netsage case, the output filter writes the flows to a network-specific RabbitMQ queue at Indiana University and the last stage is a separate logstash pipeline. The latter reads flows from the final queue using a rabbitmq input filter and sends it into elasticsearch using an elasticsearch output filter with a mapping template which sets data types for the fields. 

## Field names

The fields used/created in Logstash (and saved to Elasticsearch) are listed in the [Elasticsearch doc](elastic).


