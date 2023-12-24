#! /bin/sh

set -eux

# NOTE: Assumes start in repo root

subdomain=$1
shift

cd ./wwwroot/$subdomain
tar -cvz * > ./site.tar.gz
cd ../..

