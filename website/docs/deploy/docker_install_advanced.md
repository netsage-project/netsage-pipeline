---
id: docker_install_advanced
title: Docker Advanced Options Guide
sidebar_label: Docker Advanced Options
---

The following customizations will allow for more complex situations than described in the Docker Installation guide. Find the section(s) which apply to you.

*Please first read the Docker Installation guide in detail. This guide will build on top of that.*


## To Add Additional Sflow or Netflow Collectors

Any number of sensors can be accomodated, although if there are more than a few being processed by the same pipeline, you may run into scaling issues. 


#### a. Edit environment file

As an example, say we have three netflow sensors. In the .env file, first set `netflowSensors=3`. Then, in the next section, add the names and ports for the additional sensors using variable names ending with _2 and _3. Set the port numbers to those you have used.

```
netflowSensorName_1=The 1st Netflow Sensor Name
netflowPort_1=9000

netflowSensorName_2=The 2nd Netflow Sensor Name
netflowPort_2=9001

netflowSensorName_3=The 3rd Netflow Sensor Name
netflowPort_3=9002
```

#### b. Edit docker-composeoverride_example.yml

Add more nfacctd services to the example override file. When copying and pasting, replace _1 with _2 or _3 in three places!

```
nfacctd_1:
    ports:
      # port on host receiving flow data : port in the container
      - "${netflowPort_1}:${netflowContainerPort_1}/udp"

nfacctd_2:
    ports:
      # port on host receiving flow data : port in the container
      - "${netflowPort_2}:${netflowContainerPort_2}/udp"

nfacctd_3:
    ports:
      # port on host receiving flow data : port in the container
      - "${netflowPort_3}:${netflowContainerPort_3}/udp"
```

#### c. Rerun setup-pmacct.sh

Delete (after backing up) docker-compose.override.yml so the pmacct setup script can recreate it along with creating additional nfacctd config files. 

```
rm docker-compose.override.yml
./pmacct-setup.sh
```

Check docker-compose.override.yml and files in conf-pmacct/ for consistency.

#### d. Start new containers

If you are simply adding new collectors nfacctd_2 and nfacctd_3, and there are no changes to nfacctd_1, you can simply start up the new containers with

```sh
docker-compose up -d 
```

Otherwise, or to be safe, bring everything down first, then back up.

## To Filter Flows by Interface
If your sensors are exporting all flows, but only those using particular interfaces are relevant, use this option in the .env file. All incoming flows will be read in, but the logstash pipeline will drop those that do not have src_ifindex OR dst_inindex equal to one of those listed.  (This may create a lot of extra work and overwhelm logstash, so if at all possible, try to limit the flows at the router level or using iptables.) 

In the .env file, uncomment lines in the appropriate section and enter the information required. "ALL" can refer to all sensors or all interfaces of a sensor. If a sensor is not referenced at all, all of its flows will be kept. Be sure `ifindex_filter_flag=True` with "True" capitalized as shown, any sensor names are spelled exactly right, and list all the ifindex values of flows that should be kept and processed. Use semicolons to separate sensors. Some examples (use just one!):

```sh
ifindex_filter_keep=ALL:123
ifindex_filter_keep=Sensor 1: 123
ifindex_filter_keep=Sensor 1: 456, 789
ifindex_filter_keep=Sensor 1: ALL; Sensor 2: 800, 900
```

- In the first example, all flows that have src_ifindex = 123 or dst_ifindex = 123 will be kept, regardless of sensor name. All other flows will be discarded.
- In the 2nd case, if src or dst ifindex is 123 and the sensor name is "Sensor 1", the flow will be kept. If there are flows from "Sensor 2", all of them will be kept.
- In the 3rd case, flows from Sensor 1 having ifindex 456 or 789 will be kept.
- In the last example, all Sensor 1 flows will be kept, and those from Sensor 2 having ifindex 800 or 900 will be kept.  

Spaces don't matter except within the sensor names. Punctuation is required as shown.

## To Filter Flows by Subnet

With this option, flows from specified sensors will be dropped unless src or dst is in the list of subnets to keep.
"ALL" can refer to all sensors.
If a sensor is not referenced at all, all of its flows will be kept.

```
subnet_filter_flag=True
subnet_filter_keep=Sensor A Name: 123.45.6.0/16; Sensor B Name: 123.33.33.0/24, 456.66.66.0/24
```

## To Change a Sensor Name Depending on the Interface Used
In some cases, users want to keep all flows from a certain sensor but differentiate between those that enter or exit through a specific interface by using a different sensor name.

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 4 fields are set properly! For example,

```sh
ifindex_sensor_rename_flag=True
ifindex_sensor_rename_ifindex=10032
ifindex_sensor_rename_old_name=IU Sflow 
ifindex_sensor_rename_new_name=IU Bloomington Sflow
```

In this case, any flows from the "IU Sflow" sensor that use interface 10032 (src_ifindex = 10032 OR dst_ifindex = 10032) will have the sensor name changed from "IU Sflow" to "IU Bloomington Sflow". Currently, only one such rename can be configured in Docker and only 1 ifindex is allowed.

:::note
Please notify the devs at IU in advance, if you need to modify a sensor name, because the regexes used for determining sensor_group and sensor_type may have to be updated.
:::

## To Do Sampling Rate Corrections in Logstash
When flow sampling is done, corrections have to be applied to the number of packets and bytes. For example, if you are sampling 1 out of 100 flows, for each flow measured, it is assumed that in reality there would be 100 flows of that size with that src and dst, so the number of bits (and the number of packets, bits/s and packets/s) is multiplied by 100. Usually the collector (nfacctd or sfacctd process) gets the sampling rate from the incoming data and applies the correction, but in some cases, the sensor may not send the sampling rate, or there may be a complex set-up that requires a manual correction. 

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 3 fields are set properly! The same correction can be applied to multiple sensors by using a comma-separed list. The same correction applies to all listed sensors. For example,

```sh
sampling_correction_flag=True
sampling_correction_sensors=IU Bloomington Sflow, IU Indy Sflow
sampling_correction_factor=512
```

In this example, all flows from sensors "IU Bloomington Sflow" and "IU Indy Sflow" will have a correction factor of 512 applied by logstash. Any other sensors will not have a correction applied by logstash (presumably pmacct would apply the correction automatically).

Note that if pmacct has made a sampling correction already, no additional manual correction will be applied, even if these options are set, 
so this can be used *to be sure* a sampling correction is applied.

## To NOT deidentify flows

Normally all flows are deidentified before being saved to elasticsearch by dropping by truncating the src and dst IP addresses. If you do NOT want to do this, set full_IPs_flag to True. (You will most likely want to request access control on the grafana portal, as well.)

```
# To keep full IP addresses, set this parameter to True.
full_IPs_flag=True
```

## To Customize Java Settings / Increase Memory Available for Lostash 

If cpu or memory use seems to be a problem, try increasing the java JVM heap size for logstash from 4GB to no more than 8.

To do this, edit LS_JAVA_OPTS in the .env file. 
```yaml
LS_JAVA_OPTS=-Xmx8g -Xms8g
```

Here are some tips for adjusting the JVM heap size (https://www.elastic.co/guide/en/logstash/current/jvm-settings.html):

- Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process.
- CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves.
- Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes. As a general guideline for most installations, don’t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.


## To Bring up Kibana and Elasticsearch Containers

The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker_dev_guide#optional-elasticsearch-and-kibana)

