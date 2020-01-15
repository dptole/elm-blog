#!/bin/bash
set -ex
localdir="$(dirname "$0")"

cd "$localdir/backend"
bash build.sh

