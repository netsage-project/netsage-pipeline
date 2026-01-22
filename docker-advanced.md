# Docker Advanced Options Guide

If the basic Docker Installation does not meet your needs, the following customizations will allow for more complex situations. Find the section(s) which apply to you.

Please first read the Docker Installation guide in detail. This guide will build on top of that.

## To Add an Additional Sflow or Netflow Collector

If you have more than 1 sflow and/or 1 netflow sensor, you will need to create more collectors and modify the importer config file. The following instructions describe the steps needed to add one additional sensor. Any number of sensors can be accommodated, although if there are more than a few being processed by the same Importer, you may run into issues where long-lasting flows from sensor A time out in the aggregation step while waiting for flows from sensors B to D to be processed. (Another option might be to run more than one Docker deployment.)

### a. Edit `docker-compose.override.yml`

The pattern to add a flow collector is always the same. To add an sflow collector called `example-collector`, edit the `docker-compose.override.yml` file and add:

```yaml
  example-collector:
    image: tacc/netsage_collector:v2.1.2
    restart: always
    command: sfcapd -w /data -S 1 -z=lzo -p 9998
    volumes:
      - ./data/input_data/sflow:/data
    ports:
      - "9998:9998/udp"
```

**Notes:**

- Collector name should be meaningful
- Use `sfcapd` for sFlow or `nfcapd` for NetFlow
- Ensure the data path under `./data/` is unique
- UDP port must match the exporter

Also uncomment:

```yaml
volumes:
  - ./userConfig/netsage_override.xml:/tmp/conf/netsage_shared.xml
```

### b. Edit `netsage_override.xml`

Create a custom importer config:

```bash
cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml
```

Add a collection entry:

```xml
<collection>
  <flow-path>/data/input_data/example/</flow-path>
  <sensor>$exampleSensorName</sensor>
  <flow-type>sflow</flow-type>
</collection>
```

### c. Edit `.env`

Add the sensor name:

```env
exampleSensorName=MyNet Los Angeles sFlow
```

### d. Start the Collector

```bash
docker-compose up -d example-collector
```

## To Keep Only Flows From Certain Interfaces

```env
ifindex_filter_flag=True
ifindex_filter_keep=123,456
```

Sensor-specific:

```env
ifindex_filter_keep=Sensor 1:789
```

## To Keep or Discard Only Flows From Certain IPs or Subnets:

```env
subnet_filter_flag=False/Include/Exclude
subnet_filter_list=Sensor A Name:123.45.6.0/16;Sensor B Name:123.33.33.0/24,456.66.66.0/24
```

## To Change a Sensor Name Based on Interface

```env
ifindex_sensor_rename_flag=True
ifindex_sensor_rename_old_name=IU Sflow
ifindex_sensor_rename_new_name=IU Bloomington Sflow
ifindex_sensor_rename_ifindex=10032
```

Only one rename rule is supported.

## Sampling Rate Corrections

```env
sampling_correction_flag=True
sampling_correction_sensors=IU Bloomington Sflow, IU Sflow
sampling_correction_factor=512
```

## Change How Long Nfcapd Files Are Kept

```xml
<worker>
  <cull-enable>1</cull-enable>
  <cull-ttl>1</cull-ttl>
</worker>
```

## Change Flow Storage Location

```bash
mkdir /var/netsage
rm data/.placeholder
rmdir data
ln -s /var/netsage data
```

## Increase Logstash Memory

```env
LS_JAVA_OPTS=-Xmx4g -Xms4g
```

Optional override:

```yaml
logstash:
  image: netsage/pipeline_logstash:latest
  volumes:
    - ./userConfig/jvm.options:/usr/share/logstash/config/jvm.options
```

