#! /bin/sh

set -eux

#  NOTE: Assumes start in repo root

subdomain=$1
shift
rm -rf ./wwwroot/${subdomain}
cp -r ./src/${subdomain} ./wwwroot/${subdomain}

