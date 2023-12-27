#! /bin/sh

set -eux

cd $(dirname $(readlink -f "$0"))

subdomain=$1
shift

cd ../wwwroot/${subdomain}
hut pages publish \
    --site-config pages.json \
    -d ${subdomain}.${DOMAIN} site.tar.gz

