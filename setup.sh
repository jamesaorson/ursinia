#! /bin/sh

set -eu

sudo apt-get update -qy
sudo apt-get install --yes \
	certbot \
	nginx \
	python3-certbot-nginx \
	rsync

