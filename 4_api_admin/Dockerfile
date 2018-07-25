FROM alpine:3.7
MAINTAINER creslin
RUN apk add --no-cache curl

ENV LANG=en_US.UTF-8 \
  TERM=xterm-256color

RUN apk add --no-cache curl bash wget ca-certificates vim busybox libressl

# start a forever bash with clean trap exit
CMD tail -f /dev/null
