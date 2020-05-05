#!/usr/bin/env bash 
set -e

## Validates code and publish image for tagged branch
function integration_test {
    docker-compose -f docker-compose.build.yml build
    
    if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then 
        publish_image
    fi
}


## Publish image to our docker hub repository
function publish_image
{
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker-compose -f docker-compose.build.yml push
}


# Sets up docker compose for regression testing
function setupDocker 
{
    sudo rm /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
}

## Brings up the dashboard and executes the regression tests
function cron_regression {
    echo "Cron integration not supported"
}

# Entry point
function main
{
    if [[ "$TRAVIS_EVENT_TYPE" = "cron" ]]; then 
        cron_regression
    else
        integration_test
    fi

}

main
