#!/usr/bin/env bash

set -e

hostname=api.binance.com

local_openssl_config="
[ req ]
prompt = no
distinguished_name = req_distinguished_name
x509_extensions = san_self_signed
[ req_distinguished_name ]
CN=$hostname
[ san_self_signed ]
subjectAltName = @alt_names
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment, keyCertSign, cRLSign
extendedKeyUsage = serverAuth, clientAuth, timeStamping
[alt_names]
DNS.1 = *.binance.com
DNS.2 = localhost
DNS.3 = *.coinmarketcap.com
DNS.4 = ${hostname}
"

openssl req \
  -newkey rsa:2048 -nodes \
  -keyout "$hostname.key.pem" \
  -x509 -sha256 -days 3650 \
  -config <(echo "$local_openssl_config") \
  -out "$hostname.cert.pem"
openssl x509 -noout -text -in "$hostname.cert.pem"

cat $hostname.key.pem $hostname.cert.pem > combined.pem

rm -f 3_hitch/etc/ssl/hitch/*
mv $hostname* 3_hitch/etc/ssl/hitch/
mv combined.pem 3_hitch/etc/ssl/hitch/
