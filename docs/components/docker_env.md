Please make a copy of the .env and refer back to the docker [dev guide](../devel/docker) on details on configuring the env. Most of the default value should work just fine.

The only major change you should be aware of are the following values. The output host defines where the final data will land. The sensorName defines what the data will be labeled as.

If you don't send a sensor name it'll use the default docker hostname which changes each time you run the pipeline.

```ini
rabbitmq_output_host=rabbit
rabbitmq_output_username=guest
rabbitmq_output_pw=guest
rabbitmq_output_key=netsage_archive_input

sflowSensorName=sflowSensorName
netflowSensorName=netflowSensorName

```

Please note, the default is to have one netflow collector and one sflow collector. If you need more collectors or do no need netflow or sflow simply comment out the collector you wish to ignore.
