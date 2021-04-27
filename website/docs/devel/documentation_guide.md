---
id: docusaurus
title: Revising Documentation
sidebar_label: Docusaurus
---

This project's documentation uses Docusaurus.

Docusaurus converts markdown into html and builds a static website using React UI components, which can be exported to a webserver.

Yarn is a package manager for JavaScript and replaces the npm client. It is not strictly necessary but highly encouraged.

To extend the docs simply create a markdown file and reference the ID in the side bar config. Please see the related documentation
at the [docusaurus 2](https://v2.docusaurus.io/) project website.

## If Not Using Docker
These are instructions for editing and releasing docs without using Docker.

### Installation

To get started the first time, install npm, then use that to install yarn 
```
$ sudo yum install npm
$ sudo npm install -g yarn 
```

Git clone the netsage pipeline project, then run yarn install to get all the dependencies listed within package.json
```
$ cd netsage-pipeline/website
$ yarn install
```

### Local Development

If you are working on your local machine, you can view changes to the docs in a browser as you work. Use the following commands to generate the static website content (gets written into the build directory), then start a local development server and open up a browser window in which to view the docs. Most changes you make will be reflected live without having to restart the server.
```
$ yarn build  
$ yarn start
go to http://localhost:3000
```

### To Make Changes
Whether on a local machine or a linux host, to make changes, edit the files in website/docs/.
When finished, git add, git commit, git push, as usual.
Repeat as needed.


### Tagging a New release

When it's time to release a new version of the Pipeline, you need to create a new version of the docs as well. 

Once the documentation is stable and you don't forsee any new change, please do the following:

```
$ yarn run docusaurus docs:version a.b.c
```

replacing a.b.c with the next release version number.  
This will create new versioned docs in website/versioned_docs/.

Then edit docusaurus.config.js and change `lastVersion:` to refer to the new version number. 

Finally, commit and push the following to github:
  * website/versioned_docs/version-a.b.c/
  * website/versioned_sidebars/version-a.b.c.sidebars.json
  * versions.json 
  * docusaurus.config.js


### Deploying Tagged Docs to github.io
If Travis or some other CI is working, it will run yarn install and yarn deploy to do this automatically.

If it is not, do it manually:
```
$ USE_SSH="true" GITHUB_USER="your-username" yarn deploy   
```
replacing your-username.  This sets a couple env vars then runs 'yarn deploy' which runs 'docusaurus deploy' (see package.json) which pushes the static website created to url: "https://netsage-project.github.io" (see docusaurus.config.js) 


## If Using Docker

You may also use a docs Docker container to simplify installation, making changes, and deployment.  This method starts a local web server that allows you to see changes to the docs in a browser on your local machine, as they are made.

### Build and Start the Container

Git clone the netsage pipeline project then build and start the container. 
The Dockerfile in website/ tells how to build an image that runs yarn.  Docker-compose.yml brings up a docs container.
```
$ cd netsage-pipeline/website
$ docker-compose build build_docs
$ docker-compose up -d docs
go to http://localhost:8000/netsage-pipeline/
```

### To Make Changes
Whether on a local machine or a linux host, to make changes, edit the files in website/docs/.
When finished, git add, git commit, git push, as usual.
Repeat as needed.

### Tagging a New release

When it's time to release a new version of the Pipeline, you need to create a new version of the docs as well. 

Once the documentation is stable and you don't forsee any new change, please do the following:

```
$ docker-compose build build_docs
$ docker-compose run  docs yarn run docusaurus docs:version  a.b.c
```
replacing a.b.c with the next release version number.  
This will create new versioned docs in website/versioned_docs/.

Then edit docusaurus.config.js and change `lastVersion:` to refer to the new version number. 

Finally, commit and push the following to github:
  * website/versioned_docs/version-a.b.c/
  * website/versioned_sidebars/version-a.b.c.sidebars.json
  * versions.json 
  * docusaurus.config.js


### Deploying Tagged Docs to github.io
If Travis or some other CI is working, it will do this automatically.

If it is not, do it manually:

```sh
$ USE_SSH="true" GITHUB_USER="your-username" yarn deploy   
```

### Removing a version 

To remove version 1.2.6 for example.

we need to: 

  * update versions.json to remove the reference
  * remove the versioned_docs/version-1.2.6
  * remove versioned_sidebars/version-1.2.6-sidebars.json
