
### Shut things down

```sh
docker_compose down
```
This will stop all the docker containers, including the importer, logstash, and any collectors. Note that incoming flow data will not be saved during the time the collectors are down.

### Update Source Code

To do a Pipeline upgrade, just reset and pull changes, including the new release, from github. Your customized (non-example) env and override files will not be overwritten.

```sh
git reset --hard
git pull origin master
```

### Check/Update Files
- Compare the new docker-compose.override_example.yml file to your docker-compose.override.yml to see if a new version of Docker is required. Look for, eg, version: "3.7" at the top. If the version number is different, change it in your docker-compose.override.yml file and upgrade Docker manually.

- In the same files, see if the version of nfdump has changed. Look for lines like "image: netsage/nfdump-collector:1.6.18". If there has been a change, update the version in the override file. (You do not need to actually perform any update yourself.)
Note that you do not need to update the versions of the importer or logstash images. That will be done for you in the "select release version" stop coming up.

- Also compare your .env file with the new env.example file to see if any new lines or sections have been added. Copy new lines into your .env file, making any appropriate changes to example values.

- If you used the Docker Advanced guide to make a netsage_override.xml file, compare it to netsage_shared.xml to see if there are any changes. This is unlikely.

### Select Release Version

Run these two commands to select the new release you want to run. In the first, replace "tag_value" by the version to run (eg, v1.2.8). When asked by the second, select the same version as the tag you checked out.

Check to be sure docker-compose.yml and docker-compose.override.yml now both have the version number you selected.  

```sh
git checkout tag_value 
./scripts/docker_select_version.sh
```

### Update Docker Containers

Do not forget this stop!  This applies for both development and release versions.

```
docker-compose pull
```

### Restart Docker Containers

```
docker-compose up -d
```

This will start all the services/containers listed in the docker-compose.yml and docker-compose.override.yml files, including the importer, logstash pipeline, and collectors.
