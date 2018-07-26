# FreqCache - 2!
A docker-compose environment to control egress and ingress data from ccxt fronted trading bots for security and scalability/availability.

FreqCache aims to improve Security and Scalbility environmental factors when running CCXT fronted trading bots within docker containers.

TL;DR 
- Prevent external DNS poisoning / Hijack routing our API keys to a hacker
- Protect against bot source code, or dependency trying to send your API keys out to hacker
- Place limitting api-cache between bots and internet to prevent hitting api limits(being black listed)

To install FreqCache. 
1) Clone this repository (git clone https://github.com/creslinux/freqcache.git)
2) cd freqcache (the parent directory should keep its 'freqcache' name as expected in generated images/netowrk names)
3) run bash setup.sh 
4) *To uninstall run uninstall.sh

# Overview
![alt text](diag_images/arch_diag_fc1.png)


# Security
Security in computing is improved by depth. 
This refers to layers of technologies adding protection, so if 1 were vulnerable another mitigates the harm. 

FreqCache tightly controls both Egress (outbound) and Ingress (inbound) data flows.

A docker container connected into FreqCache can only connect out via the api-cache and only to a named exchange api-cache whitelist. 

>In June 2017 a weak password on node.js repository 
>allowed compromise upto over 52% of javascript npm packages. 
>A similar attack vector is possible for any 
>python, javascript based bot that is reliant on 3rd party libraries.

FreqCache mitigates this exposure. Should your software or linked library be compromised then no data may be taken from your host. FreqCache prevents silent Egress leaking of data.

Freqcache will stop any outbound access from a trading bot that is not explicetly whitelisted. 
The suite will read in the plain-text file "api-list" on setup. Any URIs not in this file cannot be processed by either ft_varnish or stunnel. Varnish will first reject the request. Stunnel, would not be it, but can only has channels configured that are hard-coded at setup to the white-list destinations.

> In Dec 2017 Binance, MyEtherwallet and Etherdelta
> users were compromised through DNS Hijack. 
> By taking control of an Exchanges DNS records 
> Googles Name servers, 8.8.8.8, 8.8.4.4, propogated
> IP addresses that led connections to Hackers MITM
> (man in the middle) proxy. Where API credentials and 
> Passwords were harvested. 
 

FreqCache prevents DNS lookups from any bot reaching the internet (except stunnel), as this itself may be an Egress leak of data.  Freqtrade runs two DNS servers:

1) DNSMasq - provides service to all internal bots. It will respond to any query with the IP address of hitch. 
This is used as a simple means to configure containers to direct their functional traffic to the freqcache proxy

2) unbound - provides DNS with real IP Addresses to Stunnle. unbound will only respond to requests from Stunnel. 
   unbound is configured to cache all responses for 1,000 days.   
   
This prevents any DNS poisoning or Hijacking upstream from compromising the outbound flow IP target from stunnel for HTTPS connections. The DNS can be flushed/reloaded to refresh the IP cache to update if desired (an exchange has moved its IP addres this is quite rare as exchanges provide steady API targets)
   
Many are unaware that by default Docker instances compromise the hosts firewall. 
In Linux, UFW/IPtables rules are silently compromised by Docker that allows connections from any src and to any src from and to docker containers. 

FreqCache provides a custom named Docker network to attache CCXT bots onto, with firewall rule-base to prevent ingress / egresss data flows. 

The firewall can be summarised as: 

1) Only stunnel can make outbound HTTPS connections
2) Only unbound can make outbound DNS queries
3) Containers on the ft_network can talk to each other 
4) Host 127.0.0.1 can connect to ft_network
5) ALL other ingress and egress connections are blocked

# Scalability/Availability
Exchanges are supporting more and more markets (crypto-pairs), traders are wanting to use more strategies in parallel. This is problematic as API limits are too easily hit leading to CCXT bot IP addresses being black listed. 

Where multiple trading bots are connecting to the same exchange or bot software does not make an efficient use of requesting Ticker FreqCache helps by caching data for configurable amount of seconds protecting API limits being breached. 

By default FreqCache will cache candle data for 15 seconds and ticker data for 5 seconds. This is confgurable, and may be disabled. In practice this realises a 98% drop in API calls with 5 bots trading 100 markets (pairs / ticker periods).

# Technologies
FreqCache is provided as a docker-compose.yml and compromises of:

1) Hitch SSL offload from the docker freqtade bot`
2) Varnish Api Cache
3) Stunnel SSL(HTTPS client) tunnel from api-cache to binance
4) UFW/IPtables firewall
5) DNSMask  - DNS server Inside: replies to any query with the IP of hitch. Used by clients. 
6) openssl / easyrsa CA server: Creates server certificates for every target and CA file to trust.
7) unbound - DNS server Edge: Serves Stunnel only - replies with real IPs and caches for 1,000 days to prevent poisoning.


The flow of data is CCXT DockerBot > ft_Hitch > ft_Varnish > ft_Stunnel > Exchange.

FreqCache makes use of its own private bridged Docker network from which only stunnel has outbound connectivty. There is no inbound connectivity allowed.  

# api-list (white list of allowed end-points)

Api-list is a plain-test list of URIs that after setup.sh is ran freqcache can connect to.

By default 5_ca/api-list is a complete list of all CCXT supported exhanges, plus api.coinmarketcap.com. 
Removing, or adding, any HTTPS domain into this list and running setup.sh will Prevent or Allow access to that respectively.

It is recommended to reduce this list to the minimum required. 

As example if your bot will only trade on binance, only hold the entry "api.binance.com".
All other outbound access will then be denied. 

A sample output
```
cat 5_ca/api-list
1broker.com
1btcxe.com
acx.io
anxpro.com
anybits.com
api-public.sandbox.gdax.com
```


# Connect a client
To connect a docker CCXT bot into FreqCache modify its Run script. 
Example RUN script to attach a bot to the ft_network and api_cache

The key points are
1) connect to ft_network, this puts the bot behind the firewall
2) use 10.99.7.249 as dns,  this is DNSMasq and will point all HTTPS flows to ft_hitch
3) mount and use your ca.cert to trust Hitch SNI termination

```
  mkdir -p ft_ca_root/
 cp <your install dir>/freqcache/ca.crt ft_ca_root/ca.crt


 docker run -d \
  --net="bridge" \
  --network=freqcache_ft_network \
  --dns=10.99.7.249 \
  -v $(pwd)/ft_ca_root:/ft_ca_root \
  -e SSL_CERT_FILE="/ft_ca_root/ca.crt" \
  -e CURL_CA_BUNDLE="/ft_ca_root/ca.crt" \
  -e REQUESTS_CA_BUNDLE="/ft_ca_root/ca.crt" \
  ...... <THE REMAINDER OF YOUR USUAL DOCKER RUN COMMAND>
```
This will: 
- Connect the bot to the firewalled Docker "ft_network" 
- take a copy of the certificate from ft_hitch and create a hash 
- Load certificate and CA environment variables into the bot 

This should provide the bot with seemless conenctivity to api.binance.com but no other connectivty. 

# UFW / IPtables
Freqcache makes use of Linux firwall to 
 - Prevent any outbound traffic bar Stunnel container to HTTP and DNS
 - Allow hosts on ft_network to talk to each other 
 - Allow localhost on host 'lo' to talk to containers
 - Prevent any inbound connections
 
 ```
#!/usr/bin/env bash
# Script to harden firewall to isolate ft_bridge network
#
# TLDR - only stunnel out to https, only unbound out to dsn, all other out and inbound traffic dropped.
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

# Flush the chains
iptables -F FORWARD
iptables -F DOCKER-ISOLATION

# Allow outbound HTTPs from Stunnel (7.253) and outbound DNS from unbound (7.248) only
iptables -I FORWARD 1 -s 10.99.7.248 -p udp -d 0/0 --dport 53 -j ACCEPT
iptables -I FORWARD 2 -s 10.99.7.248 -p tcp -d 0/0 --dport 53 -j ACCEPT
iptables -I FORWARD 3 -s 10.99.7.253 -p tcp -d 0/0 --dport 443 -j ACCEPT
iptables -I FORWARD 4  -d 0/0 -i ft_bridge ! -o ft_bridge -j REJECT --reject-with icmp-port-unreachable

iptables -I DOCKER-ISOLATION 1 -s 10.99.7.248 -p udp -d 0/0 --dport 53 -j ACCEPT
iptables -I DOCKER-ISOLATION 2 -s 10.99.7.248 -p tcp -d 0/0 --dport 53 -j ACCEPT
iptables -I DOCKER-ISOLATION 3 -s 10.99.7.253 -p tcp -d 0/0 --dport 443 -j ACCEPT
iptables -I DOCKER-ISOLATION 4 -d 0/0 -i ft_bridge ! -o ft_bridge -j REJECT --reject-with icmp-port-unreachable

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

# DNSMasq
DNSMasq is hosted on ft_dnsmasq 

DNSMasq is configrued to respond to any request with the IP address of the hitch host on the ft_network. 
By setting it as the dns server for all docker clients it ensure what ever endpoint they're trying to resolver will 
connect to hitch, api.binance.com as example. 

DNSMasq will respond to any client without restriction. 
DNSMasq has not upstream route/connectivity.

# unbound
Caching DNS server unbound is installed on ft_unbound. 

**Unbound will only respond to request from ft_stunnel and will provide real IP detail.***
Unbound caches and will not refresh IP resolution from upstream for 1,000 day. 

This preventing upstream DNS poisoning or hijacking from impacting our IP destination. 

Unbound can be restarted/reloaded to clear/force refresh of its DNS cache.

The configuration of unbound is read in a container start. 
The provided configuration is in 
```
7_unbound/unbound.conf
```
and reads:
```
server:
        verbosity: 1
## Interface address to listen on:
        interface: 10.99.7.248             # Listen on ft_network interface
        #interface: 0.0.0.0                  # Listen on all interfaces. Debug
        do-ip4: yes
        do-ip6: no
        do-udp: yes
        do-tcp: no
        do-daemonize: no
        logfile: ""
        #access-control: 0.0.0.0/0 allow       # to allow anyone - for build testing only
        access-control: 10.99.7.248/32 allow  # ft_unbound   (itself)
        access-control: 10.99.7.253/32 allow  # ft_stunnel   (the main purpose, client)
        #access-control: 10.99.7.250/32 allow  # ft_api_admin (for testing)
        access-control: 0.0.0.0/0 refuse     # denyall others (default policy)

## ft security - cache all dns for 100 days.
## to protect from dns poison / hijack
#
## Minimum lifetime of 8640000 100 days (86400 is 1day)
cache-min-ttl: 8640000
## Maximum lifetime of cached entries - 100 days
cache-max-ttl: 8640000
        hide-identity: yes
        hide-version: yes

forward-zone:
  name: "."
forward-addr: 8.8.8.8                        # Google as forward lookup when not in cache
```

# ft_hitch
Hitch is an SSL offload daemon provded by varnish, the leading fast cache daemon.
On start hitch mounts etc/ssl/hitch from the host 03_hitch/etc/ssl/hitch/.

This directory has been populated at install by ft_ca with the cert/key combined PEM files 
for all the api target exchanges being supported.

To support multiple certificates on a single IP hitch implement SNI matching on the inbound request.

The pem files created on your install can be viewed under: 
```
ls 3_hitch/etc/ssl/hitch/

1broker.com.pem                  api.lbank.info.pem              paymium.com.pem
1btcxe.com.pem                   api.liqui.io.pem                plus-api.btcchina.com.pem
acx.io.pem                       api.livecoin.net.pem            polon

```

# ft_varnish
Varnish is the leading web cache engine, also known as fastly. Varnish is configured out the box to cache PUBLIC kline(candle) and ticker requests for 15 and 5 seconds respectively. 

Varnish is also confiured to block and requests that are not to an entry in your api-list.
Varnish configuation files are mounted when the service is ran and can be found under: 

```
2_varnish/etc/varnish/
``` 

Varnish configuration files are built at install, running setup.sh, which calls the two listed scripts. 
The scripts loops through your api-list end points and creates a vcl rules, include, and backends for each record.

```
5_ca/varnish_vhosts.sh
5_ca/varnish_backends.sh
```

For changes to the rules to be loaded stop/star varnish

```
docker stop ft_varnish
docker start ft_varnish
```

With this structure the follwing files are present and are included in the order described:

```
default.vcl  (head of the configutation with common rules - which includes:)
> api-targets.vcl  (a list of site-enabled/a.exchange.com.vcl to include)
> backend_inc_logic.vcl
>>> sites-enabled/a.site.com.vcl
>>> sites-enabled/anoher.exchange.com.vcl
> catch-all.vcl (footer of configuration with common deny and other rules)
```
Any site without an include in api-targets.vcl and a rule file under sites-enabled/ will be returned with a HTTP err 418. 

A specific rules and backend is written for each white listed site. 
The backend will route requests for target host to an stunnel HTTP to HTTPS tunnel that is hard coded to that desitnation. 

This provides two layers of protection against egress data leaking an unintended destination.

default.vcl: ( **Ony 1 backend listed in the example, yuni_com - each white list will have its own)

```
vcl 4.0;
import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "ft_stunnel";
    .port = "8080";
}

backend yunbi_com {
    .host = "ft_stunnel";
    .port = "50144";
    .connect_timeout = 60s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 60s;
}

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "ft_stunnel";
    .port = "8080";
}


include "backend_inc_logic.vcl";

sub vcl_recv {
     # Lowercase all incoming host portion or URL
     set req.http.Host = std.tolower(regsub(req.http.Host, ":[0-9]+", ""));
     }

# Include all exchange specific configurations
include "api-targets.vcl";

# Catch all that have not matchd in all-vhosts. (Error 418 - bounce here)
include "catch-all.vcl";

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
api-targets.vcl:

```
include "sites-enabled/api.coinmarketcap.com.vcl";
include "sites-enabled/1broker.com.vcl";
include "sites-enabled/1btcxe.com.vcl";
include "sites-enabled/acx.io.vcl";
include "sites-enabled/anxpro.com.vcl";
include "sites-enabled/anybits.com.vcl";
include "sites-enabled/api-public.sandbox.gdax.com.vcl";
include "sites-enabled/api.allcoin.com.vcl";
include "sites-enabled/api.bibox.com.vcl";
include "sites-enabled/api.binance.com.vcl";
```

sites-enabled/api.binance.com.vcl

```
sub vcl_recv {
    # Only process calls to this domain
     if (req.http.Host == "api.binance.com") {
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
}
```
backend_inc_logic.vcl ( **Ony 1 backend listed in the example, yuni_com - each white list will have its own)

```
sub vcl_recv {
 if (req.http.host == "yunbi.com") {
     set req.backend_hint = yunbi_com;
 }
}
```

catch-all.vcl

```
sub vcl_recv {
    if ( req.http.Host != "ufciuwcginfhinfwihwihfixwfew" ) {
     # Has not matched a site in all-vhosts. Return a 418
        return (synth(418, "Im a teapot asked to make a coffee"));
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

```

# Stunnel 
On setup.sh the a stunnel channel for each target is written. 
Each channle has its own target destination and listens on its own TCP port.

Stunnel will forward any HTTP traffic on it channel port to its hard-coded distination.
This ensures no egress HTTPS data to any unwanted destinations that may be attempting to recieve API keys sent from compromised source bot code or include code. 

Each stunnel channel is also responsible for tests against the exchange to veryfiy the server certificate.

freqcache is configured to check, server cert is signed by a trusted CA, is from the correct host.  
```
cat api.binance.com

[api.binance.com]
client = yes
verify = 0
accept = 50008
connect = api.binance.com:443
verify = 2
CAfile = /etc/ssl/certs/ca-certificates.crt
checkhost = api.binance.com
```

```
1_stunnel/conf.d/
```
by the script
```
stunnel_channels.sh
```
as example: 
```
ls 1_stunnel/conf.d/
1broker.com                  api.lbank.info              paymium.com
1btcxe.com                   api.liqui.io                plus-api.btcchina.com
acx.io                       api.livecoin.net            poloniex.com
anxpro.com                   api.mybitx.
```



# Help and Useful Stuff.
Useful commands /info should you run into trouble

Network Schema, ft_network: 10.99.0.0/21 by default (2048 IPs available)
- ft_bridge: 10.99.0.0/21  (10.99.0.0 - 10.99.7.255)

- ft_unbound: 10.99.7.248  - DNS server/cache for stunnel. Returns real IP, caches for 1,000 days
- ft_dnsmasq: 10.99.7.249  - DNS server for clients, always returns Hitch IP to any request
- ft_api_admin: 10.99.7.250  - A jump off host with connectivity to ft_bridge host for debug
- ft_hitch: 10.99.7.251      - The SSL offload server ccxt connects to
- ft_varnish: 10.99.7.252    - Used to cache api responses, only allows cons to named target 
- ft_stunnel: 10.99.7.253    - SSL client encrypts traffic back to HTTPS to api.binance.com

There is no direct connectivity to ft_bridge network. Some debug and testing can be done from the api_admin_host which is a slimmed down alpine host with basic connectivity tools.

> 1) Connect to ft_api_admin docker which is on the ft_bridge network 
```
docker exec -it ft_api_admin bash
```

> 2) Check connectivity between ft_* hosts (from ft_api_admin)
```ping ft_hitch
ping ft_varnish
ping ft_stunnel
```

> 3) Check end-to-end is working without certificate check, from ft_api_admin : 
```
curl -k --resolve api.binance.com:443:ft_hitch https://api.binance.com/api/v1/time
```

> 4) Check end-to-end is working with certificate check, from ft_api_admin:
>(** If this works, the problem most likely is with client run conf)
```
mkdir -p ft_ca_root/
cp <your install dir>/ca.crt ft_ca_root/ca.crt
docker cp ft_ca_root/ca.crt ft_api_admin:/ca.crt

docker exec -it ft_api_admin bash 
curl --cacert /ca.cert --resolve api.binance.com:443:ft_hitch https://api.binance.com/api/v1/time
```

> 5) Connect into  the shell of a freq cache container
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

> 10.1 Check the chanels are loade for your target API endpoints. 
```
docker exec -t ft_stunnel ls /etc/stunnel/conf.d
1broker.com		     braziliex.com
1btcxe.com		     broker.negociecoins.com.br
acx.io			     btc-alpha.com
anxpro.com		     btc-trade.com.ua
anybits.com		     btc-x
```

And the contents look correct: 
```
docker exec -t ft_stunnel cat /etc/stunnel/conf.d/braziliex.com
[braziliex.com]
client = yes
verify = 0
accept = 50073
connect = braziliex.com:443
verify = 2
CAfile = /etc/ssl/certs/ca-certificates.crt
checkhost = braziliex.com
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
14) Check Hitch is provding SNI SSL termination
from ft_api_admin (not host)

```
openssl s_client -servername api.binance.com  -connect ft_hitch:443
openssl s_client -servername api.coinmarketcap.com  -connect ft_hitch:443
```

Check the right certificates is returned

# Network
> 15) Inspect docker network, confirm name the inspect 
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
> 17) Check client has ca root certificate
```
docker exec -t <CLIENT CONTAINER> ls /ft_ca_root/ca.crt
```

> 18) - removed.  


> 19) Check client REQUESTS_CA_BUNDLE and SSL_CERT_FILE are set correctly, used by URLLIB3
```
docker exec -it <CLIENT CONTAINER> bash
set 2>&1 | grep REQUESTS_CA_BUNDLE
set 2>&1 | grep SSL_CERT_FILE
``` 
> 20) Uninstall everything
```
uninstall.sh 
or (same but explicit)
#!/usr/bin/env bash
#/usr/bin/env bash
## Clear down freqcache containers, images, generated content 

docker stop ft_stunnel ft_varnish ft_hitch ft_api_admin ft_ca ft_dnsmasq ft_unbound
docker rm ft_stunnel ft_varnish ft_hitch ft_api_admin ft_ca ft_dnsmasq ft_unbound
docker rmi freqcache_ft_stunnel freqcache_ft_varnish freqcache_ft_hitch freqcache_ft_api_admin freqcache_ft_ca freqcache_ft_dnsmasq freqcache_ft_unbound

# Remove old certs and vcl configs
rm -rf 5_ca/ca
rm 3_hitch/etc/ssl/hitch/* 
rm 1_stunnel/conf.d/*

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
 
# Problem, I can only connect to abc.def.com
-  freqcache allows connections to any URI (domain) in 5_ca/api-list
To add an endpoint target add the URI in here and re-run setup. This will: 
1) Add to your CA
2) Create Vanish backend and cache rules
3) create a stunnel channel



