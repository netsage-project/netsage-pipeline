[%%%% Do you need to stop anything? Go to a particular directory?  do docker-compose up at some point?? %%%]

### Update Source Code

If the only things you did were choose the version and copy examples files to non-example files, you simply need to reset and pull updates, including the new release, from github. Your non-example env and override files will not be overwritten, but check the new example files to see if there are any updates to copy in.  [%%%% If you did make other changes, ??? %%%%]

```sh
git reset --hard
git pull origin master
```

### Docker and Collectors

Since the collectors live outside of version control, please check the docker-compose.override_example.yml to see if nfdump needs to be updated (`image: netsage/nfdump-collector:1.6.18`). Also check the docker version (`version: "3.7"`) to see if you'll need to ugrade docker.

### Select Release Version

Run these two commands to select which release you want to run. In the first, replace <tag_value> by, eg, v1.2.7. When asked by the second, select the same version as the tag you checked out.

````sh
git checkout <tag_value> 
./scripts/docker_select_version.sh
```

### Update docker containers

This applies for both development and release

```
docker-compose pull
```
