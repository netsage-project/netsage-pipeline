#!/bin/bash

# This script reads pmacct env variables from the .env file,
# creates config files from the examples, and copies the env variable
# values into them. (Needed because pmacct doesn't support using env vars)
echo ""

# Get env variables from .env file
input=".env"
# read line by line, splitting each line at "="
while IFS='=' read -r name value
do
    # save only netflow, sflow, and rabbitmq_input variables
    if [[ $name == sflow* || $name == netflow* || $name == rabbitmq_input_* ]]
    then
        ##echo "Got $name == $value" >&2
        # if this is a sensor name, we need to encode it using #'s for spaces and prefixing with "sfacct--" or "nfacct--"
        if [[ $name == sflowSensorName_* ]] 
        then
            value="${value// /#}"
            value="sfacct--${value}"
        fi
        if [[ $name == netflowSensorName_* ]] 
        then
            value="${value// /#}"
            value="nfacct--${value}"
        fi
        # export name-value pairs as env vars
        export $name="$value"
    fi
done < "$input"

# Loop over sflow sensors / create config files
port=8000
for (( n=1; n<=${sflowSensors}; n++ ))
do
    # assign the port the container will use
    # (Note that it is important to have the same internal (container) port numbers used for the same services (eg, _1) 
    # every time this script is run, since an override file with hardcoded port numbers may already exist.)
    export sflowContainerPort_$n=$port
    # create temp config files
    cp conf-pmacct/sfacctd.conf.ORIG conf-pmacct/sfacctd_$n.conf.temp
    cp conf-pmacct/sfacctd-pretag.map.ORIG conf-pmacct/sfacctd-pretag_$n.map.temp
    # change *_1 env var names to *_n
    sed -i "s/_1/_$n/g" conf-pmacct/sfacctd_$n.conf.temp
    sed -i "s/_1/_$n/g" conf-pmacct/sfacctd-pretag_$n.map.temp
    # replace all environment variables with values and save to final filenames
    envsubst < conf-pmacct/sfacctd_$n.conf.temp > conf-pmacct/sfacctd_$n.conf  
    envsubst < conf-pmacct/sfacctd-pretag_$n.map.temp > conf-pmacct/sfacctd-pretag_$n.map
    # remove temp files
    rm conf-pmacct/*.temp
    # next port number is 1 more
    port=$(($port+1))
done

# Loop over netflow sensors / create config files
port=9000
for (( n=1; n<=${netflowSensors}; n++ ))
do
    # assign the port the container will use
    # (Note that it is important to have the same internal (container) port numbers used for the same services (eg, _1) 
    # every time this script is run, since an override file with hardcoded port numbers may already exist.)
    export netflowContainerPort_$n=$port
    # create temp config files
    cp conf-pmacct/nfacctd.conf.ORIG conf-pmacct/nfacctd_$n.conf.temp
    cp conf-pmacct/nfacctd-pretag.map.ORIG conf-pmacct/nfacctd-pretag_$n.map.temp
    # change *_1 env var names to *_n
    sed -i "s/_1/_$n/g" conf-pmacct/nfacctd_$n.conf.temp
    sed -i "s/_1/_$n/g" conf-pmacct/nfacctd-pretag_$n.map.temp
    # replace all environment variables with values and save to final filenames
    envsubst < conf-pmacct/nfacctd_$n.conf.temp > conf-pmacct/nfacctd_$n.conf  
    envsubst < conf-pmacct/nfacctd-pretag_$n.map.temp > conf-pmacct/nfacctd-pretag_$n.map
    # remove temp files
    rm conf-pmacct/*.temp
    # next port number is 1 more
    port=$(($port+1))
done

# If the docker-compose.override file doesn't exist, make it by copying the example
if [[ ! -f "docker-compose.override.yml" ]]
then
    echo "Creating docker-compose.override.yml."
    cp docker-compose.override_example.yml docker-compose.override.yml 
fi

# If there are no sflow sensors, and we didn't already do it, override the sfacctd command so the container 
# just echos a line and exits right away; and set the port env vars to defaults so docker-compose doesn't complain that either is unset
if [[ ${sflowSensors} -eq 0 ]] &&  ! grep -ql "No Sflow collector" "docker-compose.override.yml" 
then
    echo "Replacing entry_point for sflow collector since it is not needed."
    sed -i "s/sfacctd_1:/sfacctd_1:\n    entrypoint: echo 'No Sflow collector.'/" docker-compose.override.yml
    export sflowPort_1=8000
    export sflowContainerPort_1=8000
fi
# Same if no netflow sensors
if [[ ${netflowSensors} -eq 0 ]] &&  ! grep -ql "No Netflow collector" "docker-compose.override.yml" 
then
    echo "Replacing entry_point for netflow collector since it is not needed."
    sed -i "s/nfacctd_1:/nfacctd_1:\n    entrypoint: echo 'No Netflow collector.'/" docker-compose.override.yml
    export netflowPort_1=9000
    export netflowContainerPort_1=9000
fi

# Replace any env variables in the override file.
envsubst < docker-compose.override.yml > docker-compose.override.yml.temp
mv docker-compose.override.yml.temp  docker-compose.override.yml


echo "Pmacct config files have been created, based on the .env file."
echo "Please check the docker-compose.override.yml file to be sure it matches the .env file!"
echo ""
