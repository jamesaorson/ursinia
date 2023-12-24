#! /bin/sh

# NOTE: Assumes start in wwwroot/

subdomain=$1
shift

cd ./$subdomain
tar -cvz $@ > ./site.tar.gz
cd ..

