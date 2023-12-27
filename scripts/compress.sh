#! /bin/sh

set -eux

cd $(dirname $(readlink -f "$0"))

subdomain=$1
shift

cd ../src/${subdomain}

cd ../../wwwroot/${subdomain}
tar -cvz * > ./site.tar.gz
cd ../../src/${subdomain}

