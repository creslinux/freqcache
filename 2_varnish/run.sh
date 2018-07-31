#!/usr/bin/env bash

set -e

sleep 1 # let compose add its hostnames

exec bash -c \
"exec /usr/sbin/varnishd -F \
   -a :80 \
   -T localhost:6082 \
   -S /etc/varnish/secret \
   -p vcc_err_unref=off \
   -p timeout_idle=330 \
   -p thread_pool_min=500 \
   -p thread_pool_max=2000 \
   -f /etc/varnish/default.vcl"

while : ; do sleep 1000; done 
