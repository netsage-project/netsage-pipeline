Please make a copy of the .env and refer back to the docker [dev guide](../devel/docker_dev_guide) on details on configuring the env. Most of the default value should work just fine.

The only major change you should be aware of are the following values. The output host defines where the final data will land. The sensorName defines what the data will be labeled as.

If you don't send a sensor name it'll use the default docker hostname which changes each time you run the pipeline.

```ini
rabbitmq_output_host=rabbit
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
rabbitmq_output_key=netsage_archive_input

sflowSensorName=sflowSensorName
netflowSensorName=netflowSensorName

## Optional configurations
## Not required, but these are exposed if you wish to use a different
## value 
aggregation_maps_path=/data/logstash-aggregation-maps ## this is configurable, but /data is required.  
inactivity_timeout=630 ##  See below
max_flow_timeout=86400 ## cut off flows that are longer the N seconds.  Default is 24 hours
```

Please note, the default is to have one netflow collector and one sflow collector. If you need more collectors or do no need netflow or sflow simply comment out the collector you wish to ignore.  If you are following the advanced guide, you'll naturally have a more complex setup for each additional collector you've configured.


### inactivity_timeout

:::note
If more than inactivity_timeout seconds have passed between the 'start' of this event and the 'start'
of the LAST matching event, OR if no matching flow has coming in for inactivity_timeout seconds
on the clock, assume the flow has ended.
Use 630 sec = 10.5 min for 5-min files,  960 sec = 16 min for AMPATH which has has 15-min files.
(For 5-min files, this allows one 5 min gap or period during which the no. of bits transferred don't meet the cutoff)
:::


