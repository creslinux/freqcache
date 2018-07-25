#!/usr/bin/env bash

if [[ "$OSTYPE" == "darwin"* ]]; then
cat <<"EOF"


 #    #   ##   #####  #    # # #    #  ####
 #    #  #  #  #    # ##   # # ##   # #    #
 #    # #    # #    # # #  # # # #  # #
 # ## # ###### #####  #  # # # #  # # #  ###
 ##  ## #    # #   #  #   ## # #   ## #    #
 #    # #    # #    # #    # # #    #  ####

-------- OSX INSTALL IMPORTANT NOTE ---------

Due to limitations of Docker in OSX it is not possible to
prevent a Docker container connecting to the internet.

If one container is allowed outbound access then all are allowed.

It is not possible to prevent a Docker container listening for
inbound connetions. If one container is allowed then all are.

These limitations are of Docker on Mac which is running in its
own Linux VM, which docker containers and netowrks are then within.

To OSX, Docker and all containers and its networks are 1 application,
that can only have a single Rule base applied.

freqCache on OSX can provide scalability and DNS protection
It cannot prevent an container with tainted code leaking data to
the internet

For full freqCache protection please install on a Linux environment.

EOF

sleep 3
read -n 1 -s -r -p "Press any key to continue or ctr-c to cancel"

fi

# Install freqcache 
chmod +x 3_hitch/build.sh
chmod +x uninstall.sh

#####
# Build CA and generate cert/keys for all URLs in 5_ca/api-list
# - Builds root CA, certs and keys for servers
# - copies ca directory with all cert and keys under 5_ca/ca/
# - copies server certs into 3_hitch/etc/ssl/hitch 
##
# clean users api-list
chmod +x 5_ca/clean_api_list.sh
5_ca/clean_api_list.sh

echo "Installing ft_ca Certificate Authority"
sleep 3
chmod +x 5_ca/build_ca_certs.sh
5_ca/build_ca_certs.sh

# Put ca.crt in parent dir to be easily found
cp 5_ca/ca/pki/ca.crt ca.crt


#####
# Build Varnish rules for each domain in 5_ca/api-list
# Rules are copied into 2_varnish/etc/varnish/sites-enabled
#
# Build Varnish Backends (V-backends must match stunnel channels)
# Backends are written into 2_varnish/etc/varnish/backends.vcl
##
chmod +x 5_ca/varnish_vhosts.sh
chmod +x 5_ca/varnish_backends.sh
5_ca/varnish_vhosts.sh
5_ca/varnish_backends.sh

#####
# Build Stunnel Channels (stunnel channels must match varnish backends)
# Stunnel channels are written into 1_stunnel/conf.d/
chmod +x 5_ca/stunnel_channels.sh
5_ca/stunnel_channels.sh


if [[ "$OSTYPE" == "darwin"* ]]; then
	echo "docker-compose requires key chain access to install"
	echo "you will also logged out of docker to allow docker-compose to install"
        # Mac OSX - needs to disable security
#	security unlock-keychain
	sleep 1
	
	echo "dear user, we are sorry, but for the next step, we need to log you out of docker"
	docker logout
fi

echo "Building images" 
sleep 3
	
docker-compose up -d 


if [[ "$OSTYPE" != "darwin"* ]]; then
	## Install firewall rules
	echo "Updating host firwall"
	sleep 3
	bash ./firewall.sh
else
	echo "Firewall not updated, firewall script is Linux only!"
	echo "OSX firewall to be included in a future releae"
	sleep 5
fi

cat <<"EOF"

#########################################################
                                                             
   ##   #####  #        ####    ##    ####  #    # ######    
  #  #  #    # #       #    #  #  #  #    # #    # #         
 #    # #    # # ##### #      #    # #      ###### #####     
 ###### #####  #       #      ###### #      #    # #         
 #    # #      #       #    # #    # #    # #    # #         
 #    # #      #        ####  #    #  ####  #    # ######    
                                                             
                                                             
 # #    #  ####  #####   ##   #      #      ###### #####     
 # ##   # #        #    #  #  #      #      #      #    #    
 # # #  #  ####    #   #    # #      #      #####  #    #    
 # #  # #      #   #   ###### #      #      #      #    #    
 # #   ## #    #   #   #    # #      #      #      #    #    
 # #    #  ####    #   #    # ###### ###### ###### #####   
 
#########################################################
To uninstall api-cache run: bash uninstall.sh 

To use api-cache connect docker containers.
Example RUN script to attach a Docker to the ft_network and api_cache
Adds ft root ca cert, sets dns

 mkdir -p ft_ca_root/
EOF
pwd=$(pwd)
echo " cp ${pwd}/ca.crt ft_ca_root/ca.crt"

cat <<"EOF"


 docker run -d \
  --net="bridge" \
  --network=freqcache_ft_network \
  --dns=10.99.7.249 \
  -v $(pwd)/ft_ca_root:/ft_ca_root \
  -e SSL_CERT_FILE="/ft_ca_root/ca.crt" \
  -e CURL_CA_BUNDLE="/ft_ca_root/ca.crt" \
  -e REQUESTS_CA_BUNDLE="/ft_ca_root/ca.crt" \
  ...... <THE REMAINDER OF YOUR USUAL DOCKER RUN COMMAND>

EOF

docker ps | grep 'freqcache_ft'

read -n 1 -s -r -p "Install complete, press any key to tail docker-compose logs, or ctr-c"
docker-compose logs -f
