#! /bin/sh

set -eux

#  NOTE: Assumes start in src/

subdomain=$1
shift
cp -r ./$subdomain ../wwwroot/

