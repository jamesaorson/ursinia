#! /bin/bash

set -euo pipefail

sudo apt-get update -qy
sudo apt-get install --yes \
	rsync \
	snapd

sudo snap install --classic \
	certbot
sudo ln -s -f /snap/bin/certbot /usr/bin/certbot
