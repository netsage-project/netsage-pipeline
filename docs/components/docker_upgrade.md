### Update Source Code

If your only changes are the version you selected simply reset and discard your changes.

```sh
git reset --hard
```

Update the git repo. Likely this won't change anything but it's always a good practice to have the latest version. You will need to do at least a git fetch in order to see the latest tags.

```sh
git pull origin master
```

### Collectors

Since the collectors live outside of version control. Please check the docker-compose.override_example.yml and see if there any changes you need to bring in.

Likely the only change of note might be the docker version.

```yaml
version: "3.7"
```

### Select Release Version

1. git checkout <tag_value> (ie. v1.2.6, v1.2.7 etc)
2. `./scripts/docker_select_version.sh` select the same version as the tag you checked out.

### Update docker containers

This applies for both development and release

```
docker-compose pull
```
