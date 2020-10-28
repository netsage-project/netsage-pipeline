---
id: logstash
title: Pipeline Logstash
sidebar_label: Logstash
---

The Logstash portion of the pipeline does most of the work, as described below.
These Logstash config files are in /etc/logstash/conf.d/

NOTE: All .conf files in conf.d/ are executed in alphabetical order. Those ending in .disabled will not be executed (assuming the pipeline config file has specified conf.d/*.conf). 

## Logstash Sequence

### 01-input-rabbit.conf

Reads flows from a rabbitmq queue. (".disabled" can be removed from other 01-input configs to get flows from other sources.)

### 10-preliminaries.conf

Drops flows to or from private IP addresses;
converts any timestamps in milliseconds to seconds;
drops events with timestamps more than a year in the past or (10 sec) in the future;
does some data type conversions;
adds @ingest_time (this is mainly for developers).

### 20-add_id.conf

Adds a unique id based on the 5-tuple of the flow (src and dst ips and ports, and protocol) plus the sensor name. This ends up being called meta.id.

### 40-aggregation.conf

Stitches together flows from different nfcapd files into longer flows, matching them up by meta.id and using a specified inactivity_timeout to decide when to start a new flow.

Notes: 

 - By default, 5-minute nfcapd files are assumed and the inactivity_timeout is set to 10.5 minutes. If more than 10.5 min have passed between the start of the current flow and the start of the last matching one, do not stitch them together.
 - If your nfcapd files are written every 15 minutes, change the inactivity_timeout to at least 16 minutes.
 - Your logstash pipeline can have only 1 worker or aggregation is not going to work!

### 45-geoip-tagging.conf

If the destination IP is in the multicast range, sets the destination Organization, Country, and Continent to "Multicast";
queries the MaxMind GeoLite2-City database by IP to get src and dst Countries, Continents, Latitudes, and Longitudes.

*This product includes GeoLite2 data created by MaxMind, available from [www.maxmind.com](http://www.maxmind.com).*

### 50-asn.conf

Normally with sflow and netflow, flows come in with source and destination ASNs.  If there is no ASN in the input event; or the input ASN is 0, 4294967295, or 23456, or it is a private ASN, try getting an ASN by IP from the MaxMind ASN database.
Sets ASN to -1 if it is unavailable for any reason.

### 53-caida-org.conf

Uses the ASN determined previously to get the organization name from the prepared CAIDA ASN-to-Organization lookup file.

*This product uses the CAIDA AS Organizations Dataset [www.caida.org](http://www.caida.org/data/as-organizations).*

### 55-member-orgs.conf

Search (optional) lookup tables by IP to obtain member or customer organization names and overwrite the Organization determined previously.
This allows entities which don't own their own ASs to be listed as the src or dst Organization.

Note: These lookup tables are not stored in github, but an example is provided to show the layout.

### 60-scireg-tagging-fakegeoip.conf

Uses a fake geoip database containing [Science Registry](http://scienceregistry.grnoc.iu.edu) information to tag the flows with source and destination science disciplines and roles, organizations and locations, etc;
removes scireg fields we don't need to save to elasticsearch.

Note: The Science Registry "fake geoip database" is updated weekly and can be downloaded from scienceregistry.grnoc.iu.edu via wget in a cron job.

### 70-deidentify.conf

Replaces the last octet of IPv4 addresses and the last 4 hextets of IPv6 addresses with x's in order to deidentify them.

### 80-privatize.org.conf

Removes information about Australian organizations (or, with modification, any country that has privacy rules that require us not to identify organizations).
If the ASN is one of those listed, completely replaces the IP with x's, sets the location to central Autralia, sets all organizations to "AARNet", removes all Projects.

### 88-preferred-location-org.conf

Copies Science Registry organization and location values, if they exist, to the preferred_organization and preferred_location fields. If there are no Science Registry values, the organizations and locations from the CAIDA and MaxMind lookups are saved to those fields.

### 90-additional-fields.conf

Sets additional quick and easy fields.  Currently we have (for Netsage's use):
 - sensor_group  = TACC, AMPATH, etc.  (based on matching sensor names to regexes)
 - sensor_type   = Circuit, Archive, Exchange Point, or Regional Network  (based on matching sensor names to regexes)
 - country_scope = Domestic, International, or Mixed  (based on src and dst countries, where Domestic = US, Puerto Rico, or Guam)
 - is_network_testing = yes, no  (yes if discipline = 'CS.Network Testing and Monitoring' or port = 5001, 5101, or 5201)

### 95-cleanup.conf

Does small misc. tasks at the end like rename, remove, or convert fields

### 98-post-process.conf

Adds @exit_time and @processing_time (these are mainly for developers)

### 99-output-rabbit.conf

Sends results to a rabbitmq queue (".disabled" can be removed from other output configs to send flows to other places)

### Final Stage 

In Netsgae's case, the last stage is a separate logstash "pipeline" on a different host. That logstash reads flows from the netsage_archive_input queue and sends it into elasticsearch. 

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


