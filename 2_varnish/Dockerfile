FROM debian:stretch
MAINTAINER creslin

ENV LANG=en_US.UTF-8 \
  TERM=xterm-256color

RUN apt-get update -q -q
#RUN apt-get upgrade --yes --force-yes
RUN apt-get install sudo apt-transport-https debian-archive-keyring runit ca-certificates curl  procps coreutils wget gnupg gnupg1 --yes --force-yes
RUN wget https://packagecloud.io/varnishcache/varnish5/gpgkey 
RUN apt-key add gpgkey
RUN echo "deb https://packagecloud.io/varnishcache/varnish5/debian/ stretch main" | sudo tee -a /etc/apt/sources.list.d/varnishcache_varnish5.list
RUN echo "deb-src https://packagecloud.io/varnishcache/varnish5/debian/ stretch main" | sudo tee -a /etc/apt/sources.list.d/varnishcache_varnish5.list
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"
RUN apt-get -y install varnish

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV CACHE_SIZE      256m
ENV VARNISHD_PARAMS ""

# ADD etc/varnish/default.vcl /etc/varnish/default.vcl

# Launch Init
#
COPY run.sh /
RUN chmod 755 /run.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
