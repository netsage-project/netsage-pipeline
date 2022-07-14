#!/bin/bash

# This script modifies docker-netsage-downloads.cron and docker-netsage-downloads.sh
# to fill in user and path info. 

# USER and PWD env vars are assumed to be already set
cp cron.d/docker-netsage-downloads.cron.ORIG  cron.d/docker-netsage-downloads.cron
sed -i "s|-USER-|$USER|" cron.d/docker-netsage-downloads.cron
sed -i "s|-PATH-TO-GIT-CHECKOUT-|$PWD|" cron.d/docker-netsage-downloads.cron
cp bin/docker-netsage-downloads.sh.ORIG  bin/docker-netsage-downloads.sh
sed -i "s|-PATH-TO-GIT-CHECKOUT-|$PWD|g" bin/docker-netsage-downloads.sh

echo ""
echo "Cron and bin files have been set up."
echo "-> Please check cron.d/docker-netsage-downloads.cron for correct user and path, "
echo "-> and copy it to /etc/cron.d/."
echo "If you need to immediately download files, run bin/docker-netsage-downloads.sh manually."
echo ""

