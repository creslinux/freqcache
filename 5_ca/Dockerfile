FROM alpine:3.7
MAINTAINER creslin

ENV EASYRSA=/usr/share/easy-rsa
ENV EASYRSA_PKI=/easyrsa/pki
ENV LANG=en_US.UTF-8 \
  TERM=xterm-256color

# Base Dependencies
RUN apk --update add  bash openssl

VOLUME /easyrsa
COPY easy-rsa /usr/share/easy-rsa

CMD tail -f /dev/null
