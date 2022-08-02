#!/bin/bash

# Copy and modify docker-netsage-downloads.cron.ORIG and .sh.ORIG
# and restart-logstash-container.cron.ORIG and .sh.ORIG
# to make non-example vesions and fill in user and path info. 
# USER NEEDS TO COPY FILES TO etc/cron.d/

# $USER and $PWD env vars are assumed to be already set
cp cron.d/docker-netsage-downloads.cron.ORIG  cron.d/docker-netsage-downloads.cron
sed -i "s|-USER-|$USER|" cron.d/docker-netsage-downloads.cron
sed -i "s|-PATH-TO-GIT-CHECKOUT-|$PWD|" cron.d/docker-netsage-downloads.cron
cp bin/docker-netsage-downloads.sh.ORIG  bin/docker-netsage-downloads.sh
sed -i "s|-PATH-TO-GIT-CHECKOUT-|$PWD|g" bin/docker-netsage-downloads.sh

cp cron.d/restart-logstash-container.cron.ORIG  cron.d/restart-logstash-container.cron
sed -i "s|-PATH-TO-GIT-CHECKOUT-|$PWD|g" cron.d/restart-logstash-container.cron
cp bin/restart-logstash-container.sh.ORIG bin/restart-logstash-container.sh
sed -i "s|-PATH-TO-GIT-CHECKOUT-|$PWD|g"  bin/restart-logstash-container.sh

echo ""
echo "    Cron and bin files have been set up."
echo "       Please check cron.d/ docker-netsage-downloads.cron and restart-logstash-container.cron"
echo "       files for correct user and path values and "
echo "          !!!! >>>>> COPY THEM TO /etc/cron.d/ <<<<< !!!! "
echo "    If you need to immediately download files, run bin/docker-netsage-downloads.sh manually."
echo ""

# Also...  When we restart logstash, the process needs to be able to write then read a file in logstash-temp/.
# Set the owner and group of logstash-temp/ to 1000, which is the default uid of the user that logstash runs as (see docker-compose.yml).
echo "    If requested, enter the sudo password to allow the script to change the owner of logstash-temp/"
echo "    (If you get an error, manually change the owner and group of logstash-temp/ to 1000. It doesn't matter what username this maps to.)"
echo ""
sudo chown 1000:1000 logstash-temp
echo ""

