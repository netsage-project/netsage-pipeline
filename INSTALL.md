# TODO: rename 'anonymizer' to 'deidentifier'
# NetSage Anonymizer Install Guide

This document covers installing the NetSage anonymization pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives.

## Installation

Installing these packages is just a yum command away. Nothing will automatically start after installation as we need to move on to configuration.

```
[root@tsds ~]# yum install grnoc-netsage-anonymizer
```

## netsage-tagger-daemon
This is a daemon that polls a Rabbit queue for flow data, retrieves it, and tags it with GeoIP/ASN/Organization information. 

## netsage-anonymizer-daemon

This is daemon that polls a Rabbit queue for tagged flow data, retrieves it, and anonymizes the IP addresses. 

The configuration files and logging configuration files are listed below:

```
/etc/grnoc/netsage/anonymizer/config.xml
/etc/grnoc/netsage/anonymizer/logging.conf
```

