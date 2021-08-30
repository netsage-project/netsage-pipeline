---
id: docker_upgrade
title: Upgrading
sidebar_label: Docker - Upgrading
---

To upgrade a previous installment of the Dockerized pipeline, perform the following steps.

### Shut things down

```sh
cd {netsage-pipeline directory}
docker-compose down
```
This will stop all the docker containers, including the importer, logstash, and any collectors. Note that incoming flow data will not be saved during the time the collectors are down.

### Update Source Code

To upgrade to a new release, pull new code from github and ine images from dockerhub. Your customized .env and override files will not be overwritten.

Update the git repo, mainly to be able to see the latest tags.
```sh
git reset --hard
git pull origin master
```

:::warning
git reset --hard will obliterate any changes you have made to non-override files.  If necessary, please make sure you commit and save to a feature branch before continuing.

Example:
```git commit -a -m "Saving local state"; git checkout -b feature/backup; git checkout master```
:::

Run these three commands to select the new release you want to run. In the first, replace "{tag}" by the version to run (eg, v1.2.10). When asked by the third, select the same version as the tag you checked out.
```sh
git checkout -b {tag} 
git pull
./scripts/docker_select_version.sh
```
Check to be sure docker-compose.yml and docker-compose.override.yml both now have the version number you selected for pipeline_importer and pipeline_logstash.  

### Check/Update Override Files
Occasionally, something may change which will necessitate editing your override and/or env file.

- Compare the new `docker-compose.override_example.yml` file to your `docker-compose.override.yml`. Look for`version: "x.x"` at the top. If the version number is different, change it in your docker-compose.override.yml file. (This is the Compose file format version.)

- Check to see if the version of nfdump has changed. Look for lines like `image: netsage/nfdump-collector:`. Make sure the version in your override file matches what is the example file. (You do not need to actually perform any upgrade yourself. This will ensure the correct version is pulled from Docker Hub.) 

- Also compare your `.env` file with the new `env.example` file to see if any new lines or sections have been added. If there have been any changes relevant to your deployment, eg, new options you want to use, copy the changes into your .env file. 

- If you used the Docker Advanced guide to make a `netsage_override.xml` file, compare it to `netsage_shared.xml` to see if there are any changes. This is unlikely.


### Update Docker Containers

Do not forget this step!  Pull new images from Docker Hub. This applies for both development and release versions.

```
docker-compose pull
```

### Restart all the Docker Containers

```
docker-compose up -d
```

This will start all the services/containers listed in the docker-compose.yml and docker-compose.override.yml files, including the importer, logstash pipeline, and collectors.

### Delete old images and containers

To save space, delete any old images and containers that are not being used.

```
docker image prune -a
docker container prune
```

