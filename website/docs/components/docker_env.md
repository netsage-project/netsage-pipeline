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

Other things you may need to edit in this file...

**Logstash output rabbit queue**: This section defines where the final data will land after going through the pipeline.  By default, it will end in a rabbitmq queue on `rabbit`, ie, the local rabbitMQ server running in its docker container. Enter a hostname to send to a remote rabbitMQ server (also the correct username, password, and queue key/name). 

::: NOTE
To send processed flow data to GlobalNOC at Indiana University, you will need to obtain settings for this section from your contact. At IU, data from the this final rabbit queue will be moved into an Elasticsearch instance for storage. 
:::

**To drop all flows except those using the specfied interfaces**: If only some flows from a router are of interest and those can be identified by interface, set the flag variable to "True" and uncomment and set the other fields. If a flow's src OR dst ifindex is in the list specified, keep it. A list of ifindexes may be scoped to a specific sensor name (which traces back to a specific port). 

**To change the sensor name for flows using a certain interface**: If you want to break out some flows coming into a port and give them a different sensor name, set the flag variable to "True" and uncomment and set the other fields. 

**To "manually" correct flow sizes and rates for sampling for specified sensors**: Once in a while, sampling corrections need to be applied by the logstash pipeline. Normally this is done automatically by nfdump in the importer. If required, set the flag variable to "True", specify which sensors need the correction, and enter N where the sampling rate is 1 out of N.

See Docker Advanced for more information about the last options.
