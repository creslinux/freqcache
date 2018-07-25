#!/usr/bin/env bash

set -e

exec bash -c \
 "exec dnsmasq --no-daemon "

while : ; do sleep 1000; done 
