#!/usr/bin/env bash
#/usr/bin/env bash
## Clear down freqcache containers, images, generated content 

docker stop ft_stunnel ft_varnish ft_hitch ft_api_admin ft_ca ft_dnsmasq ft_unbound
docker rm ft_stunnel ft_varnish ft_hitch ft_api_admin ft_ca ft_dnsmasq ft_unbound
docker rmi freqcache_ft_stunnel freqcache_ft_varnish freqcache_ft_hitch freqcache_ft_api_admin freqcache_ft_ca freqcache_ft_dnsmasq freqcache_ft_unbound

# Remove old certs and vcl configs
rm -rf 5_ca/ca
rm 3_hitch/etc/ssl/hitch/* 
