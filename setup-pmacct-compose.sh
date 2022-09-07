#!/bin/bash

# This script reads pmacct env variables from the .env file,
# [re]creates pmacct config files from the examples, and copies the env variable
# values into them. (Needed because pmacct doesn't support using env vars)
# It also [re]creates the docker-compose.yml file based on .env file entries. 

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

# Create the docker-compose.yml file by copying the example (will overwrite any existing)
echo "Creating docker-compose.yml."
# Delete all the pmacct services, ie, everything between "services:" and "rabbit:"
# -0777 = treat the whole file as one string; -e code-to-run; .../s = interpret . as any char or newline.
perl -0777 -pe "s/services:.*rabbit:/services:\n\nINSERT-HERE\n\n  rabbit:/s" < docker-compose.example.yml > docker-compose.yml

# Loop over sflow sensors / create config files (will overwrite any existing)
port=8000
for (( n=1; n<=${sflowSensors}; n++ ))
do
    # assign the port the container will use
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

    # service info for compose file; export so perl can see it.
    export section='  sfacctd_1:
    container_name: sfacctd_1
    << : *pmacct-defaults
    << : *sflow-defaults
    command:
      # parameters for the sfacctd command
      - -f
      - /etc/pmacct/sfacctd_1.conf
    ports:
      # port on host receiving flow data : port in the container
      - "${sflowPort_1}:${sflowContainerPort_1}/udp"

INSERT-HERE'

    # substitute _$n for _1 in $section
    section=$(sed 's/_1/_'"$n"'/g' <<< "$section")

    # write it into the compose file
    perl -i -pe 's/INSERT-HERE/$ENV{section}/' docker-compose.yml

    # next port number is 1 more
    port=$(($port+1))
done

# Loop over netflow sensors / create config files (will overwrite any existing)
port=9000
for (( n=1; n<=${netflowSensors}; n++ ))
do
    # assign the port the container will use
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

    # service info for compose file; export so perl can see it.
    export section='  nfacctd_1:
    container_name: nfacctd_1
    << : *pmacct-defaults
    << : *netflow-defaults
    command:
      # parameters for the nfacctd command
      - -f
      - /etc/pmacct/nfacctd_1.conf
    ports:
      # port on host receiving flow data : port in the container
      - "${netflowPort_1}:${netflowContainerPort_1}/udp"

INSERT-HERE'

    # substitute _$n for _1 in $section
    section=$(sed 's/_1/_'"$n"'/g' <<< "$section")

    # write it into the compose file
    perl -i -pe 's/INSERT-HERE/$ENV{section}/' docker-compose.yml

    # next port number is 1 more
    port=$(($port+1))
done

# Get rid of any remaining "INSERT-HERE" lines
    perl -i -pe 's/INSERT-HERE//' docker-compose.yml


# Replace any env variables in the compose file.
envsubst < docker-compose.yml > docker-compose.yml.temp
mv docker-compose.yml.temp  docker-compose.yml

echo "    Pmacct config files have been created, based on the .env file."
echo "    Docker-compose.yml has been created. Please check to be sure it matches the .env file!"
echo ""


