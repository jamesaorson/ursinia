#! /bin/bash

set -euo pipefail

sudo apt-get update -qy
sudo apt-get install --yes \
	rsync \
	snapd

sudo snap install --classic \
	certbot
