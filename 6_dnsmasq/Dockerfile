FROM alpine:latest

RUN apk --no-cache add dnsmasq bash

RUN echo 'listen-address=10.99.7.249' >> /etc/dnsmasq.conf \
	&& echo 'resolv-file=/etc/resolv.dnsmasq.conf' >> /etc/dnsmasq.conf \
	&& echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf \
	&& echo 'user=root' >> /etc/dnsmasq.conf

COPY run.sh /
RUN chmod 755 /run.sh

