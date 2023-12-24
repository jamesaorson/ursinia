#! /bin/sh

set -eux

# NOTE: Assumes start in repo root

subdomain=$1
shift

cd ./wwwroot/$subdomain
hut pages publish \
    --site-config pages.json \
    -d ${subdomain}.${DOMAIN} site.tar.gz
cd ../..

