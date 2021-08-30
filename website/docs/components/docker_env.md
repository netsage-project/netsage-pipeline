Next, copy `env.example` to `.env`  
```sh
cp env.example .env 
```

then edit the .env file to set the sensor names to unique identifiers (with spaces or not, no quotes)
```sh
# Importer settings
sflowSensorName=My sflow sensor name
netflowSensorName=My netflow sensor name
```

 - If you have only one collector, remove or comment out the line for the one you are not using.
 - If you have more than one of the same type of collector, see the "Docker Advanced" documentation.

:::note
These names uniquely identify the source of the data and will be shown in the Grafana dashboards. In elasticsearch, they are saved in the `meta.sensor_id` field. Choose names that are meaningful and unique.
For example, your sensor names might be "MyNet New York Sflow" and "MyNet Boston Netflow" or "MyNet New York - London" and "MyNet New York - Paris". Whatever makes sense in your situation.
:::

You will also likely want to change where the data is sent at the end of the logstash pipeline.

**Logstash output rabbit queue**: This section defines where the final data will land after going through the pipeline.  By default, it will end in a rabbitmq queue on `rabbit`, ie, the local rabbitMQ server running in its docker container. Enter a hostname to send to a remote rabbitMQ server (also the correct username, password, and queue key/name). 

:::note
To send processed flow data to GlobalNOC at Indiana University, you will need to obtain settings for this section from your contact. At IU, data from the this final rabbit queue will be moved into an Elasticsearch instance for storage. 
:::

The following options are described in the Docker Advanced section:

**To drop all flows except those using the specfied interfaces**: Use if only some flows from a router are of interest and those can be identified by interface.

**To change the sensor name for flows using a certain interface**: Use if you want to break out some flows coming into a port and give them a different sensor name.

**To "manually" correct flow sizes and rates for sampling for specified sensors**: Use if sampling corrections are not being done automatically (which is normally the case). 

