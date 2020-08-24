#!/usr/bin/env bash
set -e

## Validates code and publish image for tagged branch
function integration_test() {
    echo "Tag value is set to ${TRAVIS_TAG}"

    if [[ -z ${TRAVIS_TAG} ]]; then
        echo "Tag is not set, skipping"
    else
        echo "Updating configuration to select tag"
        ./scripts/docker_select_version.sh ${TRAVIS_TAG}

    fi

    docker_login

    docker-compose -f docker-compose.build.yml build

    if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
        publish_image
    fi
}

function docker_login() {
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

}
## Publish image to our docker hub repository
function publish_image() {
    docker_login
    docker-compose -f docker-compose.build.yml push
}

function sanity_test() {
    echo "Executing Sanity Check Test"
    #Create env file
    cp env.example .env
    # Bringing up the container
    docker-compose up -d
    # Waiting for something to go wrong
    sleep 120
    ## Get count of contains still up and running
    cnt=$(docker-compose ps | grep "Up" | wc -l)
    ## Validate count is 5, otherwise we fail
    if [ "$cnt" -ne 5 ]; then
        failed_containers=$(docker-compose ps | grep -v "Up" | grep "pipeline" | awk '{print $1}' | cut -d '_' -f 2)
        docker-compose logs $failed_containers
        echo "Sanity check failed expected 5 containers running and got $cnt"
        exit 1
    fi

    echo "Docker Pipeline looks stable"

}

# Sets up docker compose for regression testing
function setupDocker() {
    sudo rm /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) >docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
}

## Brings up the dashboard and executes the regression tests
function cron_regression() {
    echo "Cron integration not supported"
}

# Entry point
function main() {
    if [[ "$TRAVIS_EVENT_TYPE" = "cron" ]]; then
        cron_regression
    else
        integration_test
        sanity_test
    fi

}

main
