
### Update Source Code

To do a Pipeline upgrade, just reset and pull changes, including the new release, from github. Your non-example env and override files will not be overwritten, but check the new example files to see if there are any updates to copy in.  

```sh
git reset --hard
git pull origin master
```

### Docker and Collectors

Since the collectors live outside of version control, please check the docker-compose.override_example.yml to see if nfdump needs to be updated (eg, `image: netsage/nfdump-collector:1.6.18`). Also check the docker version (eg, `version: "3.7"`) to see if you'll need to ugrade docker.

### Select Release Version

Run these two commands to select the new release you want to run. In the first, replace "tag_value" by the version to run (eg, v1.2.8). When asked by the second, select the same version as the tag you checked out.

```sh
git checkout "tag_value" 
./scripts/docker_select_version.sh
```

### Update docker containers

This applies for both development and release

```
docker-compose pull
```
