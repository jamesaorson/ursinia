#! /bin/sh

set -eux

# NOTE: Assumes start in wwwroot/

subdomain=$1
shift

cd ./$subdomain
hut pages publish \
    --site-config pages.json \
    -d ${subdomain}.${DOMAIN} site.tar.gz
cd ..

