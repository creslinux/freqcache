#!/usr/bin/env bash

#Start dnsmaq 
service dnsmasq start

#Build config for stunnel
CONFIG="
verify = 2
CAfile = /etc/ssl/certs/ca-certificates.crt
sslVersion = all

foreground = yes

[binance]
client = yes
verify = 0
accept = 8080
connect = api.binance.com:443
"

echo "$CONFIG" > /etc/stunnel/stunnel.conf
/usr/bin/stunnel
