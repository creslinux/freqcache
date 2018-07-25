FROM alpine:3.6
MAINTAINER creslin

ADD build.sh /tmp/build.sh
RUN /tmp/build.sh

ADD start.sh /start.sh

ENV LANG=en_US.UTF-8 TERM=xterm-256color
ENV HITCH_PEM    /etc/ssl/hitch/combined.pem
ENV HITCH_BACKEND --backend=[ft_varnish]:80 
ENV HITCH_FRONTEND   --frontend=[10.99.7.251]:443
ENV HITCH_CIPHER EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH

COPY start.sh /
RUN chmod 755 /start.sh

CMD /start.sh
