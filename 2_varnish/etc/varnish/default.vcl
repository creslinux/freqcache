# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.
vcl 4.0;
import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "ft_stunnel";
    .port = "8080";
}

include "backends.vcl";

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
