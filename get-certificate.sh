#! /bin/bash

set -euo pipefail

echo "WARNING: Run this once"

cd $(dirname ${BASH_SOURCE[0]})/src

DOMAINS=""

for dir in $(ls); do
    DOMAINS="-d ${dir}.ursinia.net ${DOMAINS}"
done

sudo certbot --installer nginx ${DOMAINS}
