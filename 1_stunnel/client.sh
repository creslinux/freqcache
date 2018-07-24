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
echo "`host api.binance.com  | tail -1 | awk '{print $NF}'` api.binance.com" >> /etc/hosts
/usr/bin/stunnel
