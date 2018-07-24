#!/bin/bash

set -e

HITCH_PEM=""
for x in ` find /etc/ssl/hitch -type f -name "*.pem" ;`
do
 HITCH_PEM="$HITCH_PEM ${x}"
done
echo ${HITCH_PEM}

exec bash -c \
  "exec /usr/local/sbin/hitch --user=hitch \
  $HITCH_BACKEND \
  $HITCH_FRONTEND \
--ciphers=$HITCH_CIPHER \
  $HITCH_PEM"