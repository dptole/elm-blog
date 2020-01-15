#!/bin/sh
set -ex

# This file contains the list of commands necessary to setup the blog
# These commands are gonna be running inside the elm-mini-blog container

# Install cURL, vim & bash on alpine
apk add curl vim bash

# Install Elm 0.19.1
cd ~
curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz
gunzip elm.gz
chmod +x elm
mv elm /usr/local/bin/elm

# Install UglifyJs for a more optimized bundle
npm i -g uglify-js@3.6.4

# Run frontend
# http://localhost:8080
cd /app/frontend/
elm reactor --port 8080 &

# Run backend
# http://localhost:9090
cd /app/
bash run.sh &

# Don't stop the container on server crash
set +x
while :;
do
  echo Idle...
  date +%F_%T
  sleep $((2**20))
done
