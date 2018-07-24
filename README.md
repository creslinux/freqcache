# FreqCache
A docker-compose environment to control egress and ingress data from ccxt fronted trading bots for security and scalability/availability.

FreqCache aims to improve Security and Scalbility environmental factors when running CCXT fronted trading bots within docker containers.

To install FreqCache. 
1) Clone this repository (git clone https://github.com/creslinux/freqcache.git)
2) cd freqcache (the parent directory should keep its 'freqcache' name as expected in generated images/netowrk names)
3) run bash setup.sh 
4) *To uninstall run uninstall.sh

# Security
Security in computing is improved by depth. 
This refers to layers of technologies adding protection, so if 1 were vulnerable and exploited another mitigates the harm. 

FreqCache tightly controls both Egress (outbound) and Ingress (inbound) data flows.

A docker container connected into FreqCache can only connect out via the api-cache and only to a named exchange api-cache whitelist. 

>In June 2017 a weak password on node.js repository 
>allowed compromise upto over 52% of javascript npm packages. 
>A similar attack vector is possible for any 
>python, javascript based bot that is reliant on 3rd party libraries.

FreqCache mitigates this exposure. Should your software or linked library be compromised then no data may be taken from your host. FreqCache prevents silent Egress leaking of data.

> In Dec 2017 Binance, MyEtherwallet and Etherdelta
> users were compromised through DNS Hijack. 
> By taking control of an Exchanges DNS records 
> Googles Name servers, 8.8.8.8, 8.8.4.4, propogated
> IP addresses that led connections to Hackers MITM
> (man in the middle) proxy. Where API credentials and 
> Passwords were harvested. 

FreqCache first prevents DNS lookups from any bot, as this itself may be an Egress leak of data. Secondly the "edge" host runs DNS-Mask that is configured to host-file an exchanges IP address.  In the event of DNS hijack/poisoning bots behind FreqCache remained glued to the real exchange IP address.

Many are unaware that by default Docker instances compromise the hosts firewall. 
In Linux, UFW/IPtables rules are silently compromised by Docker that allows connections from any src and to any src from and to docker containers. 

FreqCache provides a custom named Docker network to attach CCXT bots onto, with firewall rule-base to prevent ingress / egresss data flows.

# Scalability/Availability
Exchanges are supporting more and more markets (crypto-pairs), traders are wanting to use more strategies in parallel. 
This is problematic as API limits are too easily hit leading to CCXT bot IP addresses being black listed. 

Where multiple trading bots are connecting to the same exchange or bot software does not make an efficient use of requesting Ticker and Candle data FreqCache helps by caching data for configurable amount of seconds protecting API limits being breached. 

By default FreqCache will cache candle data for 15 seconds and ticker data for 5 seconds. This is confgurable, and may be disabled. In practice this realises a 98% drop in API calls with 5 bots trading 100 markets (pairs / ticker periods).

# Technologies
FreqCache is provided as a docker-compose.yml and compromises of:

1) Hitch SSL offload from the docker freqtade bot
2) Varnish Api Cache
3) Stunnel SSL(HTTPS client) tunnel from api-cache to binance
4) UFW/IPtables firewall
5) DNSMask

The flow of data is CCXT DockerBot > ft_Hitch > ft_Varnish > ft_Stunnel > Exchange.

FreqCache makes use of its own private bridged Docker network from which only stunnel has outbound connectivty. 
There is no inbound connectivity allowed.  

By default Freqache is configured for api.binance.com 

# Connect a client!
To connect a docker CCXT bot into FreqCache modify its Run script. 
Example RUN script to attach a bot to the ft_network and api_cache

```
 file=api.binance.com.cert.pem
 mkdir hitch_cert
 docker cp ft_hitch:/etc/ssl/hitch/${file} hitch_cert/${file}
 cp "hitch_cert/$file" "hitch_cert/$(openssl x509 -hash -noout -in "hitch_cert/$file")"
 cert_hash="hitch_cert/$(openssl x509 -hash -noout -in "hitch_cert/$file")"
 
 docker run -d \
  --net="bridge" \
  --network=freqcache_ft_network \
  --add-host="api.binance.com:10.99.7.251" \
  -v $(pwd)/hitch_cert:/hitch_cert \
  -e SSL_CERT_FILE="/${cert_hash}" \
  -e REQUESTS_CA_BUNDLE="/${cert_hash}" \
  ...... <THE REMAINDER OF YOUR USUAL DOCKER RUN COMMAND> 
```
This will: 
- Connect the bot to the firewalled Docker "ft_network" 
- take a copy of the certificate from ft_hitch and create a hash 
- Load certificate and CA environment variables into the bot 

This should provide the bot with seemless conenctivity to api.binance.com but no other connectivty. 

# UFW / IPtables
Freqcache makes use of Linux firwall to 
 - Prevent any outbound traffic bar Stunnel container to HTTPS and DNS
 - Allow hosts on ft_network to talk to each other 
 - Allow localhost on host 'lo' to talk to containers
 - Prevent any inbound connections
 
 ```
 #!/usr/bin/env bash
# Script to harden firewall to isolate ft_bridge network 
#
# TLDR - only stunnel out to dns https, all other out and inbound traffic dropped.
##
if [[ $EUID -ne 0 ]]; then
   echo "This script is executing firewall.sh for ft_cache, sudo  privilage to update iptables" 
   echo "Please enter your password to continue."
fi

[ "$EUID" -eq 0 ] || exec sudo "$0" "$@"
##############
# Egress Rules: 
# Allow only stunnel to connect out for DNS, drop all other UDP traffic 
# Docker is a "bit of an arse" it can use FORWARD or DOCKER-ISOLATION... so add to both  
##

# Allow outbound DNS and HTTPs from Stunnel (7.253) only
iptables -I FORWARD 1 -s 10.99.7.253 -p udp -d 0/0 --dport 53 -j ACCEPT
iptables -I FORWARD 2 -s 10.99.7.253 -p tcp -d 0/0 --dport 443 -j ACCEPT
iptables -I FORWARD 3  -d 0/0 -i ft_bridge ! -o ft_bridge -j REJECT --reject-with icmp-port-unreachable

iptables -I DOCKER-ISOLATION 1 -s 10.99.7.253 -p udp -d 0/0 --dport 53 -j ACCEPT
iptables -I DOCKER-ISOLATION 2 -s 10.99.7.253 -p tcp -d 0/0 --dport 443 -j ACCEPT 
iptables -I DOCKER-ISOLATION 3 -d 0/0 -i ft_bridge ! -o ft_bridge -j REJECT --reject-with icmp-port-unreachable

##############
# Ingress Rules:
# Block all inbound traffic to ft_bridge interface
# allow access from lo 127.0.0.1 localhost to test services. 
# allow hosts on ft_bridge to communicate with each other
##

# Create/Flush a PRE_DOCKER chain
chain_exists()
{
    [ $# -lt 1 -o $# -gt 2 ] && { 
        echo "Usage: chain_exists <chain_name> [table]" >&2
        return 1
    }
    local chain_name="$1" ; shift
    [ $# -eq 1 ] && local table="--table $1"
    iptables $table -n --list "$chain_name" >/dev/null 2>&1
}
chain_exists B4_DOCKER || iptables -N B4_DOCKER
iptables -F B4_DOCKER

# Default Chain Rule Drop  add allow connections from local host
iptables -I B4_DOCKER -j DROP
iptables -I B4_DOCKER 1 -i lo -s 127.0.0.1  -j ACCEPT

# Allow hosts on ft_bridge to talk to each other 
iptables -I B4_DOCKER 2 -o ft_bridge -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I B4_DOCKER 3 -i ft_bridge ! -o ft_bridge -j ACCEPT
iptables -I B4_DOCKER 4 -m state --state RELATED -j ACCEPT
iptables -I B4_DOCKER 5 -i ft_bridge -o ft_bridge -j ACCEPT

# Insert to the top of FORWARD and DOCKER-ISOLATION as both can be used
iptables -I FORWARD -o ft_bridge -j B4_DOCKER
iptables -I DOCKER-ISOLATION -o ft_bridge -j B4_DOCKER
```

# DNSMask
DNSMask is hosted on ft_stunnel. 
The host itself is configured to use itslsef for DNS resolution. A feature of DNSMask is it can, by default, read entries from a local /etc/hosts file and return these as authortive to lookups. 

On start ft_stunnel takes a snapshot of api.binance.com IP address and writes to /etc/hosts. 
This protects against DNS poisoning / Hijack 

Refreshing the IP address should not be needed as exchange addresses are static; 
But in the event binance do move IP, either 
 - uninstal / setup.sh
 - docker exec -it ft_stunnel bash , and edit /etc/host

# ft_hitch
Hitch is an SSL offload daemon provded by varnish, the leading fast cache daemon.
On setup.sh Hitch generates a selfsigned certificate for api.binance.com. 
To FreqCache another exchange then edit hitch_cert_gen.sh and replace the hostname varibale within:

```#!/usr/bin/env bash

set -e

hostname=api.binance.com

local_openssl_config="
[ req ]
prompt = no
distinguished_name = req_distinguished_name
x509_extensions = san_self_signed
[ req_distinguished_name ]
CN=$hostname
[ san_self_signed ]
subjectAltName = @alt_names
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment, keyCertSign, cRLSign
extendedKeyUsage = serverAuth, clientAuth, timeStamping
[alt_names]
DNS.1 = *.binance.com
DNS.2 = localhost
DNS.3 = *.coinmarketcap.com
DNS.4 = ${hostname}
"

openssl req \
  -newkey rsa:2048 -nodes \
  -keyout "$hostname.key.pem" \
  -x509 -sha256 -days 3650 \
  -config <(echo "$local_openssl_config") \
  -out "$hostname.cert.pem"
openssl x509 -noout -text -in "$hostname.cert.pem"

cat $hostname.key.pem $hostname.cert.pem > combined.pem

rm -f 3_hitch/etc/ssl/hitch/*
mv $hostname* 3_hitch/etc/ssl/hitch/
mv combined.pem 3_hitch/etc/ssl/hitch/
```

# ft_varnish
Varnish is the leading web cache engine, also known as fastly. Varnish is configured out the box to cache PUBLIC kline(candle) and ticker requests for 15 and 5 seconds respectively. 

Varnish is also confiured to block and requests that are not to api.binance.com.
This configuration can be changed by editing the default.vcl file:

```
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.
vcl 4.0;
import std;
# Default backend definition. Set this to point to your content server.
backend default {
    .host = "ft_stunnel";
    .port = "8080";
}
sub vcl_recv {
     # Lowercase all incoming host portion or URL
     set req.http.Host = std.tolower(regsub(req.http.Host, ":[0-9]+", ""));

     # Only process calls to api.binance.com - 404 everything else. 
     if (req.http.Host != "api.binance.com") {
       return (synth(418, "Im a teapot asked to make a coffee"));
     }
	# Not a method we know about - pretened we're not here
	# pipe is right on past
     if (req.method != "GET" &&
       req.method != "HEAD" &&
       req.method != "PUT" &&
       req.method != "POST" &&
       req.method != "TRACE" &&
       req.method != "OPTIONS" &&
       req.method != "DELETE") {
         return (pipe);
     }
	# We're not going to cache anything not GET or HEAD 
	# anything other methods get a bypass first
     if (req.method != "GET" && req.method != "HEAD") {
         return (pass);
     }
	# White list of URLs to cache
	# If not one these then bypass proxy and direct to binance
     if (req.url ~ "^/api/v1/exchangeInfo" || 
	req.url ~ "^/api/v1/depth" ||
	req.url ~ "^/api/v1/trades" ||
	req.url ~ "^/api/v1/historicalTrades" ||
	req.url ~ "^/api/v1/klines" ||
	req.url ~ "^/api/v1/ticker/24hr" ||
	req.url ~ "^/api/v1/ticker/price" ||
	req.url ~ "^/api/v1/ticker/bookTicker") { 
                unset req.http.cookie;
                return(hash);
	}
	else {
                return(pass);
	}
}
sub vcl_backend_response {
	# Cache policy for matched whitelist of URLs
    if (bereq.url ~ "^/api/v1/exchangeInfo" || 
        bereq.url ~ "^/api/v1/depth" ||
        bereq.url ~ "^/api/v1/trades" ||
        bereq.url ~ "^/api/v1/historicalTrades" ||
        bereq.url ~ "^/api/v1/klines") {
		# 15sec policy
        	set beresp.ttl = 15s;
        	set beresp.http.cache-control = "public, max-age = 15s";
        	set beresp.http.X-CacheReason = "varnishcache";
        	unset beresp.http.set-cookie;
        	return(deliver);
    }
    if (bereq.url ~ "^/api/v1/ticker/24hr" ||
        bereq.url ~ "^/api/v1/ticker/price" ||
        bereq.url ~ "^/api/v1/ticker/bookTicker") {
		# 5sec policy
        	set beresp.ttl = 5s;
        	set beresp.http.cache-control = "public, max-age = 1s";
        	set beresp.http.X-CacheReason = "varnishcache";
        	unset beresp.http.set-cookie;
        	return(deliver);
    }
}
sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
}
```

# Help and Useful Stuff.
Useful commands /info should you run into trouble

Network Schema, ft_network: 10.99.0.0/21 by default (2048 IPs available)
- ft_bridge: 10.99.0.0/21  (10.99.0.0 - 10.99.7.255)

- ft_api_admin: 10.99.7.250  - A jump off host with connectivity to ft_bridge host for debug
- ft_hitch: 10.99.7.251      - The SSL offload server ccxt connects to
- ft_varnish: 10.99.7.252    - Used to cache api responses, only allows cons to named target 
- ft_stunnel: 10.99.7.253    - SSL client encrypts traffic back to HTTPS to api.binance.com

There is no direct connectivity to ft_bridge network. Some debug and testing can be done from the api_admin_host which is a slimmed down alpine host with basic connectivity tools.

>1) Connect to ft_api_admin docker which is on the ft_bridge network 
```
docker exec -it ft_api_admin bash
```

>2) Check connectivity between ft_* hosts (from ft_api_admin)
```ping ft_hitch
ping ft_varnish
ping ft_stunnel
```

>3) Check end-to-end is working without certificate check, from ft_api_admin : 
```
curl -k --resolve api.binance.com:443:ft_hitch https://api.binance.com/api/v1/time
```

>4) Check end-to-end is working with certificate check, from HOST:
>(** If this works, the problem most likely is with client run conf)
```
file=api.binance.com.cert.pem
mkdir hitch_cert
docker cp ft_hitch:/etc/ssl/hitch/${file} hitch_cert/${file}
cp "hitch_cert/$file" "hitch_cert/$(openssl x509 -hash -noout -in "hitch_cert/$file")"
 - curl --cacert hitch_cert/${file} --resolve api.binance.com:443:ft_hitch https://api.binance.com/api/v1/time
```

>5) Connect into  the shell of a freq cache container
> (from the same dir as docker-compose.yml)
```
docker-compose exec ft_stunnel bash OR docker exec -it ft_stunnel bash
docker-compose exec ft_varnish bash OR docker exec -it ft_varnish bash
docker-compose exec ft_hitch bash OR docker exec -it ft_hitch bash
```

>6) Tail Docker compose logs:
>(from the same dir as docker-compose.yml on host)
```
docker-compose logs -f
```

>7) Inspect attributes of docker containers
```
docker inspect freqcache_ft_stunnel_1
docker inspect freqcache_ft_varnish_1
docker inspect freqcache_ft_hitch_1
```

>8) Run docker-compose in the background:
```
docker-compose up -d 
```

# Stunnel: 
> 9) Check Stunnel can resolve target using its DNS mask server
```
docker-compose exec ft_stunnel nslookup api.binance.com
```

> 10) Check Stunnel can reach and download from target
```
docker-compose exec ft_stunnel curl https://api.binance.com/api/v1/time
```

# Varnish:
> 11) Check varnish configuration file is mounted, correct
```
docker-compose exec ft_varnish cat /etc/varnish/default.vcl
```

> 12) Check varnish can resolve and has network path to stunnel
```
docker-compose exec ft_varnish ping ft_stunnel 
```

> 13) Check Varnish Logs / performance: 
```
-  docker exec -it ft_varnish varnishadm  # Admin console
-  docker exec -it ft_varnish varnishlog  # Log of requests, answers, detail
-  docker exec -it ft_varnish varnishtop  # Varish Top 
-  docker exec -it ft_varnish varnishhist # Varnish histogram, ascii graph
-  docker exec -it ft_varnish varnishstat # varnish Stats, hits etc
-  docker exec -it ft_varnish varnishncsa # Log formatted to ncsa standard
-  docker exec -it ft_varnish varnishlog | egrep 'hit|Hit|HIT|Url|URL|age|Age'
                                          # useful grep of interesting log lines
```
# Hitch 
14) Check Host can connect and SSL termination is working
```
openssl s_client -connect 10.99.7.251:443
```

# Network
>15) Inspect docker network, confirm name the inspect 
```
docker network ls
docker network inspect freqcache_ft_network
```
> 16) View iptables masquerading, from host
```
sudo iptables -t nat -vL
sudo iptables -vL
```

# Client
> 17) Check client has certificate hash - should be a string similare to '69ede4a8'
```
docker exec -t <CLIENT CONTAINER> ls /hitch_cert/
```

> 18) Check certificate is for exhange target,usee hash string discovered in prior command
```
docker exec -t  <CLIENT CONTAINER> openssl x509 -noout -text -in /hitch_cert/<CERT_HASH>
```

> 19) Check client REQUESTS_CA_BUNDLE and SSL_CERT_FILE are set correctly, used by URLLIB3
```
docker exec -it <CLIENT CONTAINER> bash
set 2>&1 | grep REQUESTS_CA_BUNDLE
set 2>&1 | grep SSL_CERT_FILE
``` 
>20) Uninstall everything
```
uninstall.sh 
or (same but explicit)
docker stop ft_stunnel ft_varnish ft_hitch
docker rm ft_stunnel ft_varnish ft_hitch
docker rmi freqcache_ft_stunnel freqcache_ft_varnish freqcache_ft_hitch
```

# Other
> 21) Check connections to other sites really are denied.
```
curl -k  --resolve www.google.com:443:10.99.7.251 https://www.google.com/
```

* Should return 418 - HTTP Teapot response https://tools.ietf.org/html/rfc2324

# Customise to use another exchange:
> 22) Change default varnish cache rules, routes, timeouts
```
On the host edit the file, then uninstall, setup  
file: 2_varnish/etc/varnish/default.vcl
Edit to not 418 Teapot connections to new the target domain
```
> Change the Hitch target from binance to another exchange 
```
On host edit the file and change hostname=api.binance.com to new target
file: hitch_cert_gen.sh
uninstall and setup
```
> On Client
```
In bot client "run script" update download the new certificate from hitch and trust
 ```
 
 Uninistall and setup.sh for the changes to take affect.
 
# Problem, I can only connect to api.binance.com
-  This is by design, to prevent egress data in case of hack/corrupted source etc.


