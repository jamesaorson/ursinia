#! /bin/sh

set -eux

#  NOTE: Assumes start in src of subdomain root

subdomain=$1
shift

rm -rf ../../wwwroot/${subdomain}
cp -r . ../../wwwroot/${subdomain}
cp -r ../../shared ../../wwwroot/${subdomain}/

echo "Cleaning up what was copied over..."

rm -f ../../wwwroot/${subdomain}/*.sh

echo "Cleaned up copied content before compression"

