Start up the pipeline (all containers) using:

```sh
# docker-compose up -d
```

This will also restart any containers/processes that have died. "-d" runs containers in the background.

You can see the status of the containers and whether any have died (exited) using
```sh
# docker-compose ps
```

To check the logs for each of the containers, run

```sh
# docker-compose logs
# docker-compose logs logstash
# docker-compose logs importer
etc.
```

Add `-f` or, e.g., `-f logstash` to see new log messages as they arrive.  `--timestamps`, `--tail`,  and `--since` are also useful -- look up details in Docker documentation.

To shut down the pipeline (all containers) use

```sh
# docker-compose down
```

Run all commands from the netsage-pipeline/ directory.
