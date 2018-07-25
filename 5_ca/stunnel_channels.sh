#!/usr/bin/env bash

####
#
# Scipt to generate Stunnel channels 
# Nb* The port mapping to URL here must match
# varnish-backend. 
#
# Intended to be called from ../setup.sh

str="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
here=${str%/*}
cd ${here}

### Example output
#[binance]
#client = yes
#verify = 0
#accept = 8080
#connect = api.binance.com:443

port=50000
mkdir -p ../1_stunnel/conf.d/
for x in `cat ../5_ca/api-list | tr '[:upper:]' '[:lower:]'| grep [a-z]` 
do

CONFIG="
[${x}]
client = yes
verify = 0
accept = ${port}
connect = ${x}:443
"
echo "${CONFIG}" > ../1_stunnel/conf.d/${x}
 port=$((port + 1))
done

## send back 
cd ..
