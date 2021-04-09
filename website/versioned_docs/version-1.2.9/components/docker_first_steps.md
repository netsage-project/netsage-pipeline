#### saving this for now in case I need to put it back #######

Then checkout the latest version of the code.  If you are a developer you'll want the latest version from master, otherwise please use make sure
you've checked out the latest tagged version.

For example,
```sh
## Normal Deployment, eg, checkout version 1.2.8
$ git fetch 
$ git checkout v1.2.8 -b v1.2.8

## Developers
$ git fetch 
$ git reset --hard origin/master
```

:::warning
git reset --hard will obliterate any changes.  On initial installation, you should not have any, but if you do wish to save any state, please make sure you commit and backup to a feature branch before continuing

Example:
```git commit -a -m "Saving local state"; git checkout -b feature/backup; git checkout master```
:::


All instructions that follow assume these first steps were performed succesfully.  If not, you'll likely run into errors down the line if the code doesn't match up with the instructions provided.

