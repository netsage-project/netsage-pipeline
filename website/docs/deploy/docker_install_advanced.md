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

As an example, say we have three netflow sensors. In the .env file, first set `netflowSensors=3`. Then, in the next section, add the actual sensor names and ports for the additional sensors using variable names ending with _2 and _3. An example:

```
netflowSensorName_1=The 1st Netflow Sensor Name
netflowPort_1=9000

netflowSensorName_2=The 2nd Netflow Sensor Name
netflowPort_2=9001

netflowSensorName_3=The 3rd Netflow Sensor Name
netflowPort_3=9002
```

#### b. Rerun setup-pmacct-compose.sh

```
./setup-pmacct-compose.sh
```

Check the new docker-compose.yml and files in conf-pmacct/ for consistency.

#### d. Start new containers

To be safe, bring everything down first, then back up.

```
docker-compose down
docker-compose up -d
```

## To Filter Flows by Interface
If your sensors are exporting all flows, but only those using particular interfaces are relevant, use this option in the .env file. All incoming flows will be read in, but the logstash pipeline will drop those that do not have src_ifindex OR dst_inindex equal to one of those listed.  (Processing a large number of unecessary flows may overwhelm logstash, so if at all possible, try to limit the flows at the router level or using iptables.) 

In the .env file, uncomment lines in the appropriate section and enter the information required. "ALL" can refer to all sensors or all interfaces of a sensor. If a sensor is not referenced at all, all of its flows will be kept. Be sure `ifindex_filter_flag=True` with "True" capitalized as shown, any sensor names are spelled exactly right, and list all the ifindex values of flows that should be kept and processed. Use semicolons to separate sensors. Some examples (use just one!):

```sh
ifindex_filter_flag=True
## examples (include only 1 such line):
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

With this option, flows from specified sensors will be dropped unless src or dst is in the list of subnets to keep. It works similarly to the option to filter by interface.  "ALL" can refer to all sensors. 
If a sensor is not referenced at all, all of its flows will be kept. 

For example,

```
subnet_filter_flag=True
subnet_filter_keep=Sensor A Name: 123.45.6.0/16; Sensor B Name: 123.33.33.0/24, 456.66.66.0/24
```

## To Change a Sensor Name Depending on the Interface Used
In some cases, users want to keep all flows from a certain sensor but differentiate between those that enter or exit through a specific interface by using a different sensor name.

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all four fields are set properly! For example,

```sh
ifindex_sensor_rename_flag=True
ifindex_sensor_rename_ifindex=10032
ifindex_sensor_rename_old_name=MyNet Sflow 
ifindex_sensor_rename_new_name=MyNet Bloomington Sflow
```

In this case, any flows from the "MyNet Sflow" sensor that use interface 10032 (src_ifindex = 10032 OR dst_ifindex = 10032) will have the sensor name changed from "MyNet Sflow" to "MyNet Bloomington Sflow". 

Currently, only one such rename can be configured in Docker and only 1 ifindex is allowed.

:::note
Please notify the devs in advance, if you need to modify a sensor name, because the regexes used for determining sensor_group and sensor_type may have to be updated.
:::

## To Do Sampling Rate Corrections in Logstash
When flow sampling is done, corrections have to be applied to the number of packets and bytes. For example, if you are sampling 1 out of 100 flows, for each flow measured, it is assumed that in reality there would be 100 flows of that size with that src and dst, so the number of bits (and the number of packets, bits/s and packets/s) is multiplied by 100. Usually the collector (nfacctd or sfacctd process) gets the sampling rate from the incoming data and applies the correction, but in some cases, the sensor may not send the sampling rate, or there may be a complex set-up that requires a manual correction. 

In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 3 fields are set properly! The same correction can be applied to multiple sensors by using a semicolon-separated list. The same correction applies to all listed sensors. For example,

```sh
sampling_correction_flag=True
sampling_correction_sensors=MyNet Bloomington Sflow; MyNet Indy Sflow
sampling_correction_factor=512
```

In this example, all flows from sensors "MyNet Bloomington Sflow" and "MyNet Indy Sflow" will have a correction factor of 512 applied by logstash. Any other sensors will not have a correction applied by logstash (presumably pmacct would apply the correction automatically).

Only one correction factor is allowed for, so you can't, for example correct Sensor A with a factor of 512 and also Sensor B with a factor of 100.

>Note that if pmacct has made a sampling correction already, no additional manual correction will be applied, even if these options are set, 
>so this can be used *to be sure* a sampling correction is applied.

## To NOT Deidentify Flows

Normally all flows are deidentified before being saved to elasticsearch by truncating the src and dst IP addresses. If you do NOT want to do this, set full_IPs_flag to True. (You will most likely want to request access control on the grafana portal, as well.)

```
# To keep full IP addresses, set this parameter to True.
full_IPs_flag=True
```

## To Increase Memory Available for Lostash 

If cpu or memory usage seems to be a problem, try increasing the java JVM heap size for logstash from 4GB to 8GB.

To do this, edit LS_JAVA_OPTS in the .env file. E.g.,
```yaml
LS_JAVA_OPTS=-Xmx8g -Xms8g
```

Here are some tips for adjusting the JVM heap size (see https://www.elastic.co/guide/en/logstash/current/jvm-settings.html):

- Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process.
- CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves.
- Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes. As a general guideline for most installations, don’t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.

## To Overwrite Organization Names When an ASN is Shared

Source and destination organization names come from lookups by ASN or IP in databases provided by CAIDA or MaxMind. (The former is preferred, the latter acts as a backup.) 
Sometimes an organization that owns an AS and a large block of IPs will allow members or subentities to use certain IP ranges within the same AS. 
In this case, all flows to and from the members will have src or dst organization set to the parent organization's name. If desired, the member organizations' names can be substituted. To do so requires the use of a "member list" which specifies the ASN(s) being shared and the IP ranges for each member. 

See **conf-logstash/support/networkA-members-list.rb.example** for an example. 

## To Tag Flows with Science Discipline Information

At https://scienceregistry.netsage.global, you can see a hand-curated list of resources (IP blocks) which are linked to the organizations, sciences, and projects that use them. This information is used by the Netsage pipeline to tag science-related flows. If you would like to see your resources or projects included, please contact us to have them added to the Registry. 

## To Use IPtables to Block Some Incoming Traffic

In certain situations, you may want to use a firewall to block some of the traffic coming to your pipeline host so that it does not enter the docker containers. For example, if multiple routers must send to the same port on the host, but you only want to process flows from one of them, you can use iptables to block traffic from the those you don't want. 

With Docker, the INPUT chain in iptables is skipped and instead the FORWARDING chain is used. The first rule of the FORWARDING chain is to read the DOCKER-USER chain. This chain will contain docker rules that aren't overridden by docker. Rules that Docker creates are added to the DOCKER chain; do not manipulate this chain manually. 

To allow only a specific IP or network to access the containers, insert a negated rule at the top of the DOCKER-USER filter chain (or an accept then a drop all others). 

 
## To Bring up Kibana and Elasticsearch Containers

The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker_dev_guide#optional-elasticsearch-and-kibana)

