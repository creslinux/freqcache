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
#backend vm1 {
#    .host = "10.0.0.11";
#    .port = "80";
#    .connect_timeout = 6000s;
#    .first_byte_timeout = 6000s;
#    .between_bytes_timeout = 6000s;
#}
#######
#if (req.http.host == "www.myhost2.com") {
#    set req.backend = vm2;
#}
#}

port=50000 
# Empty the files
rm ../2_varnish/etc/varnish/backends.vcl
rm ../2_varnish/etc/varnish/backend_inc_logic.vcl
rm ../2_varnish/etc/varnish/b_end
rm ../2_varnish/etc/varnish/b_inc

for x in `cat ../5_ca/api-list | tr '[:upper:]' '[:lower:]'| grep [a-z]` 
do

# Varnish does not allow "." in backend names, replace with _
y=`echo ${x} | sed 's/\./_/g'`

# Also no numerics in Varnish labels..... varnish yey num2alpha
mod=${y//1/A} ; y=$mod
mod=${y//2/B} ; y=$mod
mod=${y//3/C} ; y=$mod
mod=${y//4/D} ; y=$mod
mod=${y//5/E} ; y=$mod
mod=${y//6/F} ; y=$mod
mod=${y//7/G} ; y=$mod
mod=${y//8/H} ; y=$mod
mod=${y//9/I} ; y=$mod
mod=${y//0/J} ; y=$mod

CONFIG_BACK="
backend ${y} {
    .host = "\"ft_stunnel\"";
    .port = "\"${port}\"";
    .connect_timeout = 60s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 60s;
}
"

CONFIG_INC="
if (req.http.host == "\"${x}\"") {
    set req.backend = ${y};
}
" 

port=$((port + 1))
echo "${CONFIG_BACK}">>../2_varnish/etc/varnish/b_end
echo "${CONFIG_INC}">>../2_varnish/etc/varnish/b_inc

done

# fill backends.vcl backend_inc_logic.vcl ( includeds in default.vcl)
cat ../2_varnish/etc/varnish/b_end>>../2_varnish/etc/varnish/backends.vcl
cat ../2_varnish/etc/varnish/b_inc>>../2_varnish/etc/varnish/backend_inc_logic.vcl

# Send back 
cd ..
