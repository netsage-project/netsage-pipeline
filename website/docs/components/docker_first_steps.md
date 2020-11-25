### First

If you haven't already, install [Docker](https://www.docker.com) and [Docker Compose](https://docs.docker.com/compose/install/) and clone this [project](https://github.com/netsage-project/netsage-pipeline.git) from github.

ensure you are on the latest version of the code.  If you are a developer you'll want the latest version from master, otherwise please use make sure
you've checkout the latest tag.


:::warning
git reset --hard will obliterate any changes.  If you wish to save any state, please make sure you commit and backup to a feature branch before continuing

Example:
```git commit -a -m "Saving local state"; git checkout -b feature/backup; git checkout master```

:::

Example:

```sh
##Developer
git fetch; git reset --hard origin/master
## Normal Deployment
git fetch; git checkout v1.2.7 -b v1.2.7
```

All instructions that follow assume the First steps were performed succesfully.  If not you'll likely run into errors down the line if the code doesn't line up with the instructions provided.

