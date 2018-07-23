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
