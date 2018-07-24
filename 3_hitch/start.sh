#!/bin/bash

set -e

exec bash -c \
  "exec /usr/local/sbin/hitch --user=hitch \
  $HITCH_BACKEND \
  $HITCH_FRONTEND \
--ciphers=$HITCH_CIPHER \
  $HITCH_PEM"
