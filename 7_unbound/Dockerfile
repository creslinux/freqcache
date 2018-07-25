FROM alpine:3.8
MAINTAINER creslin

RUN apk add --no-cache --update unbound bash
COPY unbound.conf /etc/unbound/unbound.conf
COPY resolv.conf /etc/resolv.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh 
RUN unbound-checkconf

CMD ["/run.sh"]
