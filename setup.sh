#!/usr/bin/env bash


# Install freqcache 
chmod +x 3_hitch/build.sh
chmod +x hitch_cert_gen.sh
chmod +x uninstall.sh

# Build CA and generate cert/keys for all URLs in 5_ca/api-list
echo "Installing ft_ca Certificate Authority"
sleep 3
chmod +x 5_ca/run.sh
5_ca/run.sh

#Copy pem files into hitch certificate directory
cp 5_ca/ca/pki/pem/*.pem 3_hitch/etc/ssl/hitch/

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

# download hitch certificate
 file=api.binance.com.cert.pem
 mkdir hitch_cert
 docker cp ft_hitch:/etc/ssl/hitch/${file}  hitch_cert/${file}
 cp "hitch_cert/$file" "hitch_cert/$(openssl x509 -hash -noout -in "hitch_cert/$file")"
 cert_hash="hitch_cert/$(openssl x509 -hash -noout -in "hitch_cert/$file")"

# launch run container.
 docker run -d \
  --net="bridge" \
  --network=freqcache_ft_network \
  --add-host="api.binance.com:10.99.7.251" \
  -v $(pwd)/hitch_cert:/hitch_cert \
  -e SSL_CERT_FILE="/${cert_hash}" \
  -e REQUESTS_CA_BUNDLE="/${cert_hash}" \
  ...... <THE REMAINDER OF YOUR USUAL DOCKER RUN COMMAND> 

EOF
docker ps | grep 'freqcache_ft'

