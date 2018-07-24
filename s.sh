#!/usr/bin/env bash


# Install freqcache 
chmod +x 3_hitch/build.sh
chmod +x hitch_cert_gen.sh
chmod +x uninstall.sh

# Build CA and generate cert/keys for all URLs in 5_ca/api-list 
chmod +x 5_ca/run.sh
5_ca/run.sh

#Copy pem files into hitch certificate directory 
cp 5_ca/ca/pki/pem/*.pem 3_hitch/etc/ssl/hitch/

