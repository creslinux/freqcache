#!/usr/bin/env bash
########################
#
# Script to build CA root certs
# and all server certs and keys
# or any URL in the txt file
# 5_ca/api-list
#
# Certs/keys for servers are copied 
# in Hitch's cert directory for use
#
# Intended to be called from parent dir
# from setup.sh
#
########################

######
# Glue exection to its own directory 
##
str="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
here=${str%/*}
cd ${here}

######
# build easy-rsa CA server 
##
docker build -t freqcache_ft_ca .
docker run -d --name ft_ca freqcache_ft_ca

docker exec -it ft_ca /usr/share/easy-rsa/easyrsa init-pki
docker exec -it ft_ca /usr/share/easy-rsa/easyrsa build-ca nopass
docker exec -it ft_ca /usr/share/easy-rsa/easyrsa  gen-dh

#####
# For every URL in ap-list text file create a server certificate and key 
# URLs are 1 per line.
##
for x in `cat api-list `  
do 
   docker exec -it ft_ca /usr/share/easy-rsa/easyrsa build-server-full ${x} nopass
done

#####
# Copy the resultant ca directory structure to host, 
# This holds the generated root ca and server certs/keys
##
docker cp ft_ca:/easyrsa ca

#####
# combine the hexidecimal portions of the cert and keys
# for each server to create a combined pem file
##
mkdir ca/pki/pem
for x in `cat api-list `
do 
  grep -A 1000 BEGIN ca/pki/issued/${x}.crt > c
  grep -A 1000 BEGIN  ca/pki/private/${x}.key > k
  cat c k > ${x}.pem
  mv ${x}.pem ca/pki/pem/${x}.pem
  echo "##################################################################"
  echo " Built Cert and Key for ${x} "
  echo "##################################################################"
  cat  ca/pki/pem/${x}.pem
  rm c
  rm k
done

#####
# Copy pem files into hitch certificate directory
# hitch will use to SSL terminate connections
##
cp ca/pki/pem/*.pem ../3_hitch/etc/ssl/hitch/

# Back to parent dir.
cd ..
