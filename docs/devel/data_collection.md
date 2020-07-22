---
id: data_collection
title: Data Collection
sidebar_label: Data Collection
---

We currently have two patterns for data collection.

## Legacy

Simply run the docker stack as is.  You can ommit the filebeat container as it's not used.

## New Pattern

The importer and collector are no longer needed.  Please update the filebeat docker-compose to expose port:

``` yaml
    ports:
     - "9999:9999/udp" ## netflow collector
```

Note you cannot run the collector and filebeat at the same time. You will need to choose one or the other.

### Configuration

the logstash config has several plugins that are available but disabled by default.  Please have a look at the conf-logstash directory 
and rename anything that might be useful to end with a .conf.

## Testing

[testing.py](https://github.com/netsage-project/netsage-pipeline/blob/feature/netflow/replayData/testing.py) is provided to send a single payload message to rabbitmq. If you need more data you may want to replay a network capture using netflow.sh.  Please see [README.md](https://github.com/netsage-project/netsage-pipeline/blob/master/replayData/README.md) for more info.
