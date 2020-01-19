#!/bin/bash
set -ex
localdir="$(dirname "$0")"
pwdlocaldir="$(pwd)/$localdir"
API_URL=http://localhost:9090/elm-blog

cd "$localdir/../frontend"
# [elm make] debug/optimize ? -> o
# [env]      dev/prod       ? -> prod
bash "build.sh" "o" "prod"

cp elm.min.js "$pwdlocaldir/public/dist/js/elm.min.js"

cd "$localdir/.."
. .env
cd "$localdir"

NEW_API_URL="${API_URL//\//\\\/}"

sed -r 's/(API_URL) = .*/\1 = "'$NEW_API_URL'";/' "$pwdlocaldir/public/src/index.html" > "$pwdlocaldir/public/dist/index.html"
