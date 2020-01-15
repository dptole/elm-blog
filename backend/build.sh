#!/bin/bash
set -ex
localdir="$(dirname "$0")"
pwdlocaldir="$(pwd)/$localdir"

cd "$localdir/../frontend"
# [elm make] debug/optimize ? -> o
# [env]      dev/prod       ? -> prod
bash "build.sh" "o" "prod"

cp elm.min.js "$pwdlocaldir/public/js/elm.min.js"

