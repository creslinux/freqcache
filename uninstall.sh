docker stop ft_stunnel ft_varnish ft_hitch ft_api_admin ft_ca
docker rm ft_stunnel ft_varnish ft_hitch ft_api_admin ft_ca
docker rmi freqcache_ft_stunnel freqcache_ft_varnish freqcache_ft_hitch freqcache_ft_api_admin freqcache_ft_ca
# Remove old certs
rm -rf 5_ca/ca
rm 3_hitch/etc/ssl/hitch/* 
