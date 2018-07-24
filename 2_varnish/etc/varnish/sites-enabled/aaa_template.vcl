    # Only process calls to this domain
     if (req.http.Host == "aaa_template.com") {
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