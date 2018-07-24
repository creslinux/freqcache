#!/usr/bin/env bash


# Install freqcache 
chmod +x 3_hitch/build.sh
chmod +x hitch_cert_gen.sh

# Generate certificate for Hitch 
echo "generating ceritifate for hitch" 
sleep 3
bash hitch_cert_gen.sh

echo "Building images" 
sleep 3

if [[ "$OSTYPE" == "darwin"* ]]; then
	echo "dear user, we are sorry, but we require to unlock you keychain for this step"
        # Mac OSX - needs to disable security
	security unlock-keychain
	sleep 1
	
	echo "dear user, we are sorry, but for the next step, we need to log you out of docker"
	docker logout
fi

	
docker-compose up -d 


if [[ "$OSTYPE" != "darwin"* ]]; then
	## Install firewall rules
	echo "Updating host firwall"
	sleep 3
	bash ./firewall.sh
else
	echo "sorry firewall is not supported, under this operation system!"
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
 docker cp ft_hitch:/etc/ssl/hitch/${file} hitch_cert/${file}
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

