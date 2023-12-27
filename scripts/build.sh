#! /bin/sh

set -eux

cd $(dirname $(readlink -f "$0"))

subdomain=$1
shift

cd ../src/${subdomain}

rm -rf ../../wwwroot/${subdomain}
cp -r . ../../wwwroot/${subdomain}
rm -rf ../../wwwroot/${subdomain}/shared
cp -r ../../shared ../../wwwroot/${subdomain}/

echo "Cleaning up what was copied over..."

rm -f ../../wwwroot/${subdomain}/*.sh

echo "Cleaned up copied content before compression"

