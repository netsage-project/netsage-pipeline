---
id: docker_install_advanced
title: Docker Advanced Options Guide
sidebar_label: Docker Advanced Options
---

If the basic Docker Installation does not meet your needs, the following customizations will allow for more complex situations. Find the section(s) which apply to you.

*Please first read the Docker Installation guide in detail. This guide will build on top of that.*


## To Add an Additional Sflow or Netflow Collector

If you have more than 1 sflow and/or 1 netflow sensor, you will need to create more collectors and modify the importer config file. The following instructions describe the steps needed to add one additional sensor.

Any number of sensors can be accomodated, although if there are more than a few being processed by the same Importer, you may run into issues where long-lasting flows from sensosr A time out in the aggregation step while waiting for flows from sensors B to D to be processed. (Another option might be be to run more than one Docker deployment.) 


#### a. Edit docker-compose.override.yml

The pattern to add a flow collector is always the same. To add an sflow collector called example-collector, edit the docker-compose.override.yml file and add something like

```yaml
  example-collector:
    image: netsage/nfdump-collector:alpine-1.6.23
    restart: always
    command: sfcapd -T all -l /data -S 1 -w -z -p 9997
    volumes:
      - ./data/input_data/example:/data
    ports:
      - "9997:9997/udp"
```

- collector name: should be updated to something that has some meaning, in our example "example-collector".
- image: copy from the default collector sections already in the file. 
- command: choose between "sfcapd" for sflow and "nfcapd" for netflow, and at the end of the command, specify the port to watch for incoming flow data.  
- volumes: specify where to write the nfcapd files. Make sure the path is unique and in ./data/. In this case, we're writing to ./data/input_data/example. Change "example" to something meaningful.
- ports: make sure the port here matches the port you've set in the command. Naturally all ports have to be unique for this host and the router should be configured to export data to the same port. (?? If the port on your docker container is different than the port on your host/local machine, use container_port:host_port.) 

Make sure the indentation is right or you'll get an error about yaml parsing.

You will also need to uncomment these lines: 

```yaml
  volumes:
     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml
```


#### b.  Edit netsage_override.xml

To make the Pipeline Importer aware of the new data to process, you will need to create a custom Importer configuration: netsage_override.xml.  This will replace the usual config file netsage_shared.xml. 

```sh
cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml
```

Edit netsage_override.xml and add a new "collection" section for the new sensor as in the following example. The flow-path should match the path set above in docker-compose.override.yml. $exampleSensorName is a new "variable"; don't replace it here, it will be replaced with a value that you set in the .env file. For the flow-type, enter "sflow" or "netflow" as appropriate. (Enter "netflow" if you're running IPFIX.)

```xml
    <collection>
        <flow-path>/data/input_data/example/</flow-path>
        <sensor>$exampleSensorName</sensor>
        <flow-type>sflow</flow-type>
    </collection>
```

#### c. Edit environment file

Then, in the .env file, add a line that sets a value for the "variable" you referenced above, $exampleSensorName. The value is the name of the sensor which will be saved to elasticsearch and which appears in Netsage Dashboards. Set it to something meaningful and unique. E.g.,

```ini
exampleSensorName=MyNet Los Angeles sFlow
```


#### d. Running the new collector

After doing the setup above and selecting the docker version to run, you can start the new collector by running the following line, using the collector name (or by running `docker-compose up -d` to start up all containers):

```sh
docker-compose up -d example-collector
```

## To Keep Only Flows From Certain Interfaces
If your sensors are exporting all flows, but only those using a particular interface are relevant, use this option in the .env file. The collectors and importer will save/read all incoming flows, but the logstash pipeline will drop those that do not have src_ifindex OR dst_inindex equal to one of those listed. 

In the .env file, uncomment lines in the appropriate section and enter the information required. Be sure `ifindex_filter_flag=True` with "True" capitalized as shown, any sensor names are spelled exactly right, and list all the ifindex values of flows that should be kept and processed. Some examples (use just one!):

```sh
ifindex_filter_keep=123
ifindex_filter_keep=123,456
ifindex_filter_keep=Sensor 1: 789
ifindex_filter_keep=123; Sensor 1: 789; Sensor 2: 800, 900
```

In the first case, all flows that have src_ifindex = 123 or dst_ifindex = 123 will be kept, regardless of sensor name. (Note that this may be a problem if you have more than 1 sensor with the same ifindex values!) 
In the 2nd case, if src or dst ifindex is 123 or 456, the flow will be processed. 
In the 3rd case, only flows from Sensor 1 will be filtered, with flows using ifindex 789 kept. 
In the last example, any flow with ifindex 123 will be kept. Sensor 1 flows with ifindex 789 (or 123) will be kept, and those from Sensor 2 having ifindex 800 or 900 (or 123) will be kept.  

Spaces don't matter except within the sensor names. Punctuation is required as shown.


## To Change a Sensor Name Depending on the Interface Used
In some cases, users want to keep all flows from a certain sensor but differentiate between those that enter or exit through specific sensor interfaces. This can be done by using this option in the .env file.

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 4 fields are set properly! For example,

```sh
ifindex_sensor_rename_flag=True
ifindex_sensor_rename_old_name=IU Sflow 
ifindex_sensor_rename_new_name=IU Bloomington Sflow
ifindex_sensor_rename_ifindex=10032
```

In this case, any flows from the "IU Sflow" sensor that use interface 10032 (src_ifindex = 10032 OR dst_ifindex = 10032) will have the sensor name changed from "IU Sflow" to "IU Bloomington Sflow". Currently, only one such rename can be configured in Docker and only 1 ifindex is allowed.

:::note
Please notify the devs at IU in advance, if you need to modify a sensor name, because the regexes used for determining sensor_group and sensor_type may have to be updated.
:::

## To Do Sampling Rate Corrections in Logstash
When flow sampling is done, corrections have to be applied. For example, if you are sampling 1 out of 100 flows, for each flow measured, it is assumed that in reality there would be 100 flows of that size with that src and dst, so the number of bits (and the number of packets, bits/s and packets/s) is multiplied by 100. Usually the collector (nfcapd or sfcapd process) gets the sampling rate from the incoming data and applies the correction, but in some cases, the sensor may not send the sampling rate, or there may be a complex set-up that requires a manual correction. With netflow, a manual correction can be applied using the '-s' option in the nfsen config, if nfsen is being used, or the nfcapd command, but this is not convenient when using Docker. For sflow, there is no such option. In either case, the correction can be made in logstash as follows.

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 3 fields are set properly! The same correction can be applied to multiple sensors by using a comma-separed list. The same correction applies to all listed sensors. For example,

```sh
sampling_correction_flag=True
sampling_correction_sensors=IU Bloomington Sflow, IU Sflow
sampling_correction_factor=512
```

## To Change How Long Nfcapd Files Are Kept
The importer will automatically delete older nfcapd files for you, so that your disk doesn't fill up. By default, 3 days worth of files will be kept. This can be adjusted by making a netsage_override.xml file:

```sh
cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml
```

At the bottom of the file, edit this section to set the number of days worth of files to keep. Set cull-enable to 0 for no culling. Eg, to save 1 days worth of data:
````xml
  <worker>
    <cull-enable>1</cull-enable>
    <cull-ttl>1</cull-ttl>
  </worker>
````

You will also need to uncomment these lines in docker-compose.override.yml: 

```yaml
  volumes:
     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml
```


## To Save Flow Data to a Different Location

By default, data is saved to subdirectories in the ./data/ directory (ie, the data/ directory in the git checkout).  If you would like to use a different location, there are two options.

1. The best solution is to create a symlink between ./data/ and the preferred location, or, for an NFS volume, export it as ${PROJECT_DIR}/data.

During installation, delete the data/ directory (it should only contain .placeholder), then create your symlink. Eg, to use /var/netsage/ instead of data/, 
```sh
cd {netsage-pipeline dir}
mkdir /var/netsage
rm data/.placeholder
rmdir data
ln -s /var/netsage {netsage-pipeline dir}/data
```
(Check the permissions of the directory.)

2. Alternatively, update volumes in docker-compose.yml and docker-compose.override.yml Eg, to save nfcapd files to subdirs in /mydir, set the collector volumes to `- /mydir/input_data/netflow:/data` (similarly for sflow) and set the importer and logstash volumes to `- /mydir:/data`. 

:::warning
If you choose to update the docker-compose file, keep in mind that those changes will cause a merge conflict or be wiped out on upgrade.
You'll have to manage the volumes exported and ensure all the paths are updated correctly for the next release manually.
:::

## To Customize Java Settings / Increase Memory Available for Lostash 


If cpu or memory seems to be a problem, try increasing the JVM heap size for logstash from 2GB to 3 or 4, no more than 8.

To do this, edit LS_JAVA_OPTS in the .env file. 
```yaml
LS_JAVA_OPTS=-Xmx4g -Xms4g
```

Here are some tips for adjusting the JVM heap size (https://www.elastic.co/guide/en/logstash/current/jvm-settings.html):

- Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process.
- CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves.
- Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes. As a general guideline for most installations, don’t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.

To modify other logstash settings, rename the provided example file for JVM Options and tweak the settings as desired:

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

## To Bring up Kibana and Elasticsearch Containers

The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker_dev_guide#optional-elasticsearch-and-kibana)

