---
id: docker_install_advanced
title: Docker Advanced Installation Guide
sidebar_label: Docker Advanced
---

If the Docker Simple installation does not meet your needs, the following customizations will allow for more complex situations.

*Please first read the Docker Simple installation guide in detail. This guide will build on top of that.*


## To Add an Additional Sflow or Netflow Collector

If you have more than 1 sflow and/or 1 netflow sensor, you will need to create more collectors and modify the importer config file. The following instructions describe the steps needed to add one additional sensor.

Any number of sensors can be accomodated, although if there are more than a few being processed by the same Importer, you may run into issues where long-lasting flows from sensosr A time out in the aggregation step while waiting for flows from sensors B to D to be processed. (Another option might be be to run more than one Docker deployment.) 


### 1. Edit docker-compose.override.yml

The pattern to add a flow collector is always the same. To add an sflow collector called example-collector, edit the docker-compose.override.yml file and add

```yaml
  example-collector:
    image: netsage/nfdump-collector:1.6.18
    restart: always
    command: sfcapd -T all -l /data -S 1 -w -z -p 9997
    volumes:
      - ./data/input_data/example:/data
    ports:
      - "9997:9997/udp"
```

- collector-name: should be updated to something that has some meaning, in our example "example-collector".
- command: choose between sfcapd for sflow and nfcapd for netflow, and at the end of the command, specify the port to watch for incoming flow data.  (Unless your flow exporter is already set up to use a different port, you can use the default ports and configure the exporters on the routers to match.)
- ports: make sure the port here matches the port you've set in the command. Naturally all ports have to be unique for this host and the 
router should be configured to export data to the same port. (If the port on your docker container is different than the port on your host/local machine, use container_port:host_port.) 
- volumes: specify where to write the nfcapd files. Make sure the path is unique and in ./data/. In this case, we're writing to ./data/input_data/example. Change the last part of the path to something meaningful.

You will also need to uncomment these lines: 

```yaml
  volumes:
     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml
```


### 2.  Edit netsage_override.xml

To make the Pipeline Importer aware of the new data to process, you will need to create a custom Importer configuration: netsage_override.xml.  This will replace the usual config file netsage_shared.xml. 

```sh
cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml
```

Edit netsage_override.xml and add a "collection" section for the new sensor as in the following example. The flow-path should match the path set above in docker-compose.override.yml. $exampleSensorName is a new "variable"; it will be replaced with a value set in the .env file. For the flow-type, enter "sflow" or "netflow" as appropriate.

```xml
    <collection>
        <flow-path>/data/input_data/example/</flow-path>
        <sensor>$exampleSensorName</sensor>
        <flow-type>sflow</flow-type>
    </collection>
```

### 3. Edit environment file

Then, in the .env file, add a line that sets a value for the "variable" you referenced above, $exampleSensorName. The value is the name of the sensor which will be saved to elasticsearch and which appears in Netsage Dashboards. Set it to something meaningful and unique.

```ini
exampleSensorName=Example New York sFlow
```


### Running the new collector

After doing the setup above and selecting the docker version to run, you can start the new collector by running the following line, using the collector name (or by running `docker-compose up -d` to start up all containers):

```sh
docker-compose up -d example-collector
```

:::note
The default version of the collector is 1.6.18. There are other versions released and :latest should be point to the latest one, but there is no particular effort made to make sure we released the latest version. You can get a listing of all the current tags listed [here](https://hub.docker.com/r/netsage/nfdump-collector/tags) and the source to generate the docker image can be found [here](https://github.com/netsage-project/docker-nfdump-collector) the code for the You may use a different version though there is no particular effort to have an image for every nfdump release.
:::


## To Change a Sensor Name Depending on the Interface Used
In some cases, users want to differentiate between flows that enter or exit through specific sensor interfaces. This can be done by editing the env file.

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 4 fields are set properly! For example,

```sh
ifindex_sensor_rename_flag=True
ifindex_sensor_rename_old_name=IU Sflow 
ifindex_sensor_rename_new_name=IU Bloomington Sflow
ifindex_sensor_rename_ifindex=10032
```

In this case, any flows through interface 10032 (src_ifindex = 10032 OR dst_ifindex = 10032) will have the sensor name (sensor_id) changed from "IU Sflow" to "IU Bloomington Sflow". Currently, only one such rename can be configured in Docker.

:::note
Please notify the devs at IU in advance, if you need to modify a sensor name, because the regexes used for determining sensor_group and sensor_type may have to be updated.

## To Do Sampling Rate Corrections in Logstash
When flow sampling is done, the number of bits needs to be corrected for the sampling rate. For example, if you are sampling 1 out of 100 flows and a sample has 55 MB, it is assumed that in reality there would be 100 flows of that size (with that src and dst), so the number of bits is multiplied by 100. Usually the collector (nfcapd or sfcapd process) gets the sampling rate from the incoming data and applies the correction, but in some cases, the sensor may not send the sampling rate, or there may be a complex set-up that requires a manual correction. With netflow, a manual correction can be applied using the '-s' option in the nfsen config or the nfcapd command. For sflow, there is no such option. In either case, the correction can be made in logstash as follows.

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 3 fields are set properly! The same correction can be applied to multiple sensors by using a comma-separed list. For example,

```sh
sampling_correction_flag=True
sampling_correction_sensors=IU Bloomington Sflow, IU Sflow
sampling_correction_factor=512
```

## To Change How Long Nfcapd Files Are Kept
The importer will automatically delete older nfcapd files for you, so that your disk don't fill up. By default, 3 days worth of files will be kept. This can be adjusted by making a netsage_override.xml file:

```sh
cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml
```

At the bottom of the file, edit this section to set the number of days worth of files to keep. Set cull-enable to 0 for no culling. Eg, to save 7 days worth of data:
````xml
  <worker>
    <cull-enable>1</cull-enable>
    <cull-ttl>7</cull-ttl>
  </worker>
````

You will also need to uncomment these lines in docker-compose.override.yml: 

```yaml
  volumes:
     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml
```



## To Process Tstat Data
Tstat data is not collected by nfdump/sfcapd/nfcapd or read by an Importer. Instead, the flow data is sent directly from the router or switch to the logstash pipeline's ingest rabbit queue (named "netsage_deidentifier_raw").  So, when following the Docker Simple guide, the sections related to configuring and starting up the collectors and Importer will not pertain to the tstat sensors. The .env file still needs to be set up though.

Setting up Tstat is outside the scope of this document, but see the Netsage project Tstat-Transport which contains client programs that can send tstat data to a rabbit queue. See [https://github.com/netsage-project/tstat-transport.git](https://github.com/netsage-project/tstat-transport.git). Basically, you need to have Tstat send data directly to the same rabbit queue that the importers write sflow and netflow data to and that the logstash pipeline reads from.


## To Customize Java Settings / Increase Memory Available for Lostash 

If you need to modify the amount of memory logstash can use or any other java settings,
rename the provided example for JVM Options and tweak the settings as desired.

```sh
cp userConfig/jvm.options_example userConfig/jvm.options
```

Also update the docker-compose.override.xml file to uncomment lines in the logstash section. It should look something like this:

```yaml
logstash:
  image: netsage/pipeline_logstash:latest
  volumes:
    - ./userConfig/jvm.options:/usr/share/logstash/config/jvm.options
```

Here are some tips for adjusting the JVM heap size (https://www.elastic.co/guide/en/logstash/current/jvm-settings.html):

- The recommended heap size for typical ingestion scenarios should be no less than 4GB and no more than 8GB.
- CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves.
- Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes. As a general guideline for most installations, don’t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.
- Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process.

## To Bring up Kibana and Elasticsearch Containers

The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker_dev_guide#optional-elasticsearch-and-kibana)

## For Data Saved to an NFS Volume

By default, data is saved to subdirectories in the ./data directory.  If you would like to use an NFS mount instead you will need to either

1. export the NFS volume as ${PROJECT_DIR}/data (which is the idea scenario and least intrusive)
2. update the path to the NFS export path in all locations in docker-compose.yml and docker-compose.override.yml

Note: modifying all the paths in the two files should work, but may not. In one case, it worked to modify only the paths for the collector volumes (eg, - /mnt/nfs/netsagedata/netflow:/data), leaving all others with their default values.

:::warning
If you choose to update the docker-compose file, keep in mind that those changes will cause a merge conflict on upgrade.
You'll have to manage the volumes exported and ensure all the paths are updated correctly for the next release manually.
:::
