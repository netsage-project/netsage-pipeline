#!/usr//bin/env bash

function displayVersions() {
  echo "Current Released Tags"
  git tag -l
}

function selectVersion() {
  displayVersions
  echo -n "Which version would you like to use?  "
  read version
  updateDocker $version

}

function updateDocker() {
  version=$1
  echo "Selecting $version, updating docker configuration"
  sed -i -e "s/:latest/:$version/" docker-compose.build.yml
  sed -i -e "s/:latest/:$version/" docker-compose.yml
  if test -f "docker-compose.override.yml"; then
    sed -i -e "s/:latest/:$version/" docker-compose.override.yml
  fi

}

if [ $# -gt 0 ]; then
  updateDocker $1
else
  selectVersion
fi
