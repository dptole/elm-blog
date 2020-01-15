#!/bin/bash
set -x

localdir="$(dirname "$0")"
if [ "$localdir" == "." ]
then
  localdir=""
fi

dockerdir="$(pwd)/$localdir"
blogdir="$(dirname "$dockerdir")"

$dockerdir/remove-container.sh

sudo docker run \
  -d \
  -v "$blogdir":/app/ \
  -p 9090:9090 \
  -p 8080:8080 \
  -w /app/ \
  --restart always \
  --name elm-blog \
  node:12-alpine \
  /app/docker/entrypoint.sh

sudo docker logs -f --tail 10 elm-blog

