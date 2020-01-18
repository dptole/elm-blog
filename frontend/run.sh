#!/bin/bash
set -ex
localdir="$(dirname "$0")"

bash "$localdir/build.sh"

elm reactor --port 8080

