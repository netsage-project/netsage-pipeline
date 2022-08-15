---
id: docker_upgrade
title: Upgrading
sidebar_label: Docker - Upgrading
---

To upgrade a previous installment of the Dockerized pipeline, perform the following steps.

### 1. Shut things down

```sh
cd {netsage-pipeline directory}
docker-compose down
```
This will stop and remove all the docker containers. Note that incoming flow data will be lost during the time the collector and rabbit containers are down.

### 2. Update source code

To upgrade to a new release, first pull updates from github. Your customized .env and override files will not be overwritten, nor will files created by startup scripts, cache files, or downloaded support files, though it's always good to make backup copies. 

```sh
git reset --hard
git pull origin master
```

:::warning
git reset --hard will obliterate any changes you have made to non-override files, eg, logstash conf files.  If necessary, please make sure you commit and save to a feature branch before continuing.
:::

Checkout the version of the pipeline you want to run (replace "{tag}" by the version number, eg, v1.2.11) and make sure it's up to date. 
```sh
git checkout -b {tag} 
git pull
```

### 3. Recreate and check custom files

- Compare the .env to env.example to see if any changes have been made. 
    Copy in any updates, particularly any relevant ones, or just recreate the .env file as you did during installation. 

- Run the pmacct setup script to recreate the pmacct config files, in case there have been any changes. This might also update the override file.

```sh
./setup-pmacct.sh
```

- Compare the docker-compose.override.yml file to the example. (Expect the example file to have environment variables that have gotten filled in in the non-example file.) If there are new lines or sections that are missing, copy them in. The setup script is not able to handle much in the way of changes.

- Rerun the cron setup script to recreate the non-ORIG files in bin/ and cron.d/. 

```sh
./setup-cron.sh
```

- Compare the resulting .cron files in the cron.d/ directory to those in /etc/cron.d/. If any have changed, copy them to /etc/cron.d/.

### 4. Restart all the Docker Containers

```
docker-compose up -d
```

This will start all the services/containers listed in the docker-compose.yml and docker-compose.override.yml files, pulling down any new docker images that are required.

### 5. Delete old images and containers

To keep things tidy, delete any old images and containers that are not being used.

```
docker image prune -a
docker container prune
```

To check which images you have
```
docker image ls
```

