---
id: docusaurus
title: Documentation Guide
sidebar_label: Documentation Guide
---


# Using Local Tools

This project's documentation is using docusaurus to generate docs from markdown files and loaded in a react app.

To extend the doc simply create a markdown file and reference the ID in the side bar. Please see the related documentation
at the [docusaurus 2](https://v2.docusaurus.io/) project website.

## Installation

```
$ yarn install
```

## Local Development

```
$ yarn start
```

This command starts a local development server and open up a browser window. Most changes are reflected live without having to restart the server.

## Build

```
$ yarn build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

# Using Docker

## Build the container

```
docker-compose build build_docs
```

## Deployments

### Local Development

```
docker-compopse up -d docs
```

The docs will be visible at http://localhost:8000/netsage-pipeline/


### Manual Deployment

This should be handled by the CI (Continuous Integration) currently setup via Travis for each commit merged into master.  If you need to do this manually, you can force a deployment
assuming you have write access to the git repo by running the following command.

```sh
USE_SSH="true" GITHUB_USER="<youruser>" yarn deploy
```



## Tagging New release

Once the documentation is stable and you don't forsee any new change, please do the following:

```
yarn run docusaurus docs:version 1.1.0
```

Where 1.1.0 is the next release version.  Commit the new directories created under 

:::note
Alternatively, if you have docker setup, you may run this command and avoid installing all of the required javascript dependencies.

```
docker-compose run  docs yarn run docusaurus docs:version  1.1.0
```
:::

(note if image is not built yet, please run: `docker-compose build build_docs`)

  * website/versioned_docs
  * website/versioned_sidebars
  * versions.json 

Update the docusaurus.config.js

```
lastVersion: '1.2.6' 
```

should point to the latest value.

### Removing a version 

To remove version 1.2.6 for example.

we need to: 

  * update versions.json to remove the reference
  * remove the versioned_docs/version-1.2.6
  * remove versioned_sidebars/version-1.2.6-sidebars.json
