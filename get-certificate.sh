#! /bin/sh

set -eu

echo "WARNING: Run this once"
sudo certbot --manual --installer nginx -d 'ursinia.net' -d '*.ursinia.net'
