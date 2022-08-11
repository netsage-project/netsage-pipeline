Next, copy `env.example` to `.env`  then edit the .env file to set the sensor names, ports, and where to send processed flows.

```sh
cp env.example  .env 
```

:::note
Sensor names uniquely identify the source of the data and will be shown in the Grafana dashboards so they should be understandable by a general audience.  For example, your sensor names might be "MyNet New York Sflow" or "MyNet New York to London". (Running your proposed names by a Netsage admin would be helpful.)
:::

- By default, the number of sflowSensors and netflowSensors is set to 1 at the top.  If you know from the start that you will have only 1 sensor, set either sflowSensors or netflowSensors to 0 and comment out the sensor name and port below.

    If you will have more than 1 of one type of sensor, see the Docker Advanced Options documentation.

- In the next section of the .env file, declare the name of sflow sensor 1 and the port to which the exporter is sending the flows. Similarly for netflow sensor 1.

- You will also want to edit the **rabbit_output** variables. This section defines where the final data will land after going through the pipeline.  By default, it will be written to a rabbitmq queue on `rabbit`, ie, the local rabbitMQ server running in the docker container, but there is nothing provided to do anything further with it.

    :::note
    To send processed flow data to Indiana University, you will need to obtain settings for this section from your contact. A new queue may need to be set up at IU, as well as allowing traffic from your pipeline host. (At IU, data from the this final rabbit queue will be moved into an Elasticsearch instance for storage and viewing in Netsage Portals.)
    :::


