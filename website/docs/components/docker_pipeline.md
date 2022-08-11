Start up the pipeline (all containers) using

```sh
docker-compose up -d
```

This command will pull down all required docker images and start all the services/containers as listed in the docker-compose.yml and docker-compose.override.yml files.
In general, it will also restart any containers/processes that have died. "-d" runs containers in the background.

You can see the status of the containers and whether any have died (exited) using these commands
```sh
docker-compose ps
docker container ls
```

To check the logs for each of the containers, run

```sh
docker-compose logs logstash
docker-compose logs rabbit
docker-compose logs sfacctd_1
docker-compose logs nfacctd_1
```

Add `-f`, e.g. `-f logstash` to see new log messages as they arrive.  `--timestamps`, `--tail`,  and `--since` are also useful -- look up details in Docker documentation.

To shut down the pipeline (all containers) use

```sh
# docker-compose down
```

Run all commands from the netsage-pipeline/ directory.
