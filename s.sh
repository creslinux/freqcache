#!/usr/bin/env bash


# Install freqcache 
chmod +x 3_hitch/build.sh
chmod +x hitch_cert_gen.sh
chmod +x uninstall.sh
chmod +x 5_ca/run.sh

5_ca/run.sh

docker ps | grep 'freqcache_ft'

