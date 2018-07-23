FROM debian:stretch
MAINTAINER creslin

ENV LANG=en_US.UTF-8 \
  TERM=xterm-256color


RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y stunnel4 dnsmasq dnsutils vim iputils-ping ca-certificates curl && \
  openssl genrsa > /root/stunnel.key && \
  openssl req -new -key /root/stunnel.key -x509 -days 9999 -out /root/stunnel.crt -subj "/C=US" && \
  cat /root/stunnel.* > /etc/stunnel/stunnel.pem && \ 
  chmod 600 /etc/stunnel/stunnel.pem

# This image to use real DNS, avoid hosts name cache deamon
# run docker with --dns=127.0.0.1 to use its own dns service. 

RUN echo 'hosts: dns files' > /etc/nsswitch.conf

# /etc/hosts values
#RUN echo 'address="/examplehostentry/127.0.0.1"' >> /etc/dnsmasq.d/0hosts

# dnsmasq configuration
RUN echo 'listen-address=10.99.7.253' >> /etc/dnsmasq.conf
RUN echo 'resolv-file=/etc/resolv.dnsmasq.conf' >> /etc/dnsmasq.conf
RUN echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf
RUN echo 'user=root' >> /etc/dnsmasq.conf

# google dns
RUN echo 'nameserver 8.8.8.8' >> /etc/resolv.dnsmasq.conf
RUN echo 'nameserver 8.8.4.4' >> /etc/resolv.dnsmasq.conf


COPY stunnel /etc/default/
COPY client.sh /
RUN chmod 755 /client.sh
