---
id: docker_install_advanced
title: Docker Advanced Installation Guide
sidebar_label: Docker Advanced
---

If the Docker Simple installation does not meet your needs, the following customizations will allow for more complex situations.

Please first read the Docker Simple installation guide in detail. This guide will build on top of that.


{@import ../components/docker_first_steps.md}

## To Add an Additional Sflow or Netflow Collector

If you have more than 1 sflow and/or 1 netflow sensor, you will need to create more collectors and modify the importer config file. The following instructions describe the steps needed to add one additional sensor.

Any number of sensors can be accomodated, although if there are more than a few being processed by the same Importer, you may run into issues where long-lasting flows from sensosr A time out while waiting for flows from sensors B-D to be processed. (Another option might be be to run more than one Docker deployment.) 


### 1. docker-compose.override.yml

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


### 2.  netsage_override.xml

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

### 3. Environment file

Then, in the .env file, add a line that sets a value for the "variable" you referenced above, $exampleSensorName. The value is the name of the sensor which will be saved to elasticsearch and which appears in Netsage Dashboards. Set it to something meaningful and unique.

```ini
exampleSensorName="Example New York sFlow"
```

### Select which version to run

Before continuing you need to choose if you are going to be use the 'Develop' version which has the latest changes but might be a bit less stable (or have code not ready for use) or a 'Released' version. If you're opting to use the Develop version, then simply skip the version selection step.

:::caution
Warning! it is HIGHLY recommended to not use the :latest as that is intended to be a developer release. You may still use it but be aware that you may have some instability each time you update.
:::

```sh
  git fetch 
  git checkout "tag name"
  ./scripts/docker_select_version.sh
```

Replace "tag name" with the version you intend to use, eg, "v1.2.5".  When prompted by the script, select the same version.


### Running the new collector

After selecting the docker version to run, you can start the new collector by running the following line, using the collector name:

```sh
docker-compose up -d example-collector
```

:::note
The default version of the collector is 1.6.18. There are other versions released and :latest should be point to the latest one, but there is no particular effort made to make sure we released the latest version. You can get a listing of all the current tags listed [here](https://hub.docker.com/r/netsage/nfdump-collector/tags) and the source to generate the docker image can be found [here](https://github.com/netsage-project/docker-nfdump-collector) the code for the You may use a different version though there is no particular effort to have an image for every nfdump release.
:::


## For Tstat Data
Tstat data is not collected by nfdump/sfcapd/nfcapd or read by an Importer. Instead, the flow data is sent directly from the router or switch to the logstash pipeline's ingest rabbit queue (named "netsage_deidentifier_raw").  So, when following the Docker Simple guide, the sections related to configuring and starting up the collectors and Importer will not pertain to the tstat sensors. The .env file still needs to be set up though.

Setting up Tstat is outside the scope of this document, but see the Netsage project Tstat-Transport which contains client programs that can send tstat data to a rabbit queue. See [https://github.com/netsage-project/tstat-transport.git](https://github.com/netsage-project/tstat-transport.git).


## To Customize Logstash Java Settings

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

## To Bring up Kibana and Elasticsearch Containers

The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components.

This isn't a production pattern but the tools can be useful at times. Please refer to the [Docker Dev Guide](../devel/docker_dev_guide#optional-elasticsearch-and-kibana)

## To Export Data to an NFS Volume

By default, data is saved to subdirectories in the ./data directory.  If you would like to use an NFS mount instead you will need to either

1. export the NFS volume as ${PROJECT_DIR}/data (which is the idea scenario and least intrusive)
2. update the path to the NFS export path in all locations in docker-compose.yml and docker-compose.override.yml


:::warning
If you choose to update the docker-compose file, keep in mind that those changes will cause a merge conflict on upgrade.
You'll have to manage the volumes exported and ensure to update all the paths correctly for the next release manually.
:::
