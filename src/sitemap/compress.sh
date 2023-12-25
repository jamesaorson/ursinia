#! /bin/sh

set -eux

# NOTE: Assumes start in src of subdomain root

subdomain=$1
shift

cd ../../wwwroot/${subdomain}
tar -cvz * > ./site.tar.gz
cd ../../src/${subdomain}

