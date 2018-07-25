#!/usr/bin/env bash

###
# Script to generate varnish mapping to 
# stunnel channels . 
# *NB URL / PORT mapping here MUST match varish backends. 
#
# Intended to be called from ../setup.sh
##

str="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
here=${str%/*}
cd ${here}

#### Example output - include
#if (req.http.host == "www.myhost2.com") {
#    set req.backend = vm2;
#}
#### Example output - backend 
#backend vm1 {
#    .host = "10.0.0.11";
#    .port = "80";
#    .connect_timeout = 6000s;
#    .first_byte_timeout = 6000s;
#    .between_bytes_timeout = 6000s;
#}

port=50000 
>../2_varnish/etc/varnish/backends.vcl

for x in `cat ../5_ca/api-list | tr '[:upper:]' '[:lower:]'| grep [a-z]` 
do

CONFIG_INC="
if (req.http.host == "\"${x}\"") {
    set req.backend = ${x};
}
" 

CONFIG_BACK="
backend ${x} {
    .host = "\"ft_stunnel\"";
    .port = "\"${port}\"";
    .connect_timeout = 60s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 60s;
}
"
port=$((port + 1))

echo "${CONFIG_INC}">>../2_varnish/etc/varnish/backends.vcl
echo "${CONFIG_BACK}">>../2_varnish/etc/varnish/backends.vcl

done

# Send back 
cd ..
