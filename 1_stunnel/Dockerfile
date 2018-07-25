FROM debian:stretch
MAINTAINER creslin

ENV LANG=en_US.UTF-8 \
  TERM=xterm-256color

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y stunnel4 dnsutils vim iputils-ping ca-certificates curl && \
  openssl genrsa > /root/stunnel.key && \
  openssl req -new -key /root/stunnel.key -x509 -days 9999 -out /root/stunnel.crt -subj "/C=US" && \
  cat /root/stunnel.* > /etc/stunnel/stunnel.pem && \ 
  chmod 600 /etc/stunnel/stunnel.pem

RUN echo 'hosts: dns files' > /etc/nsswitch.conf

COPY stunnel /etc/default/
COPY client.sh /
RUN chmod 755 /client.sh
