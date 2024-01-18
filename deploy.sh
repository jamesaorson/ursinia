#! /bin/sh

set -eu

sudo mkdir -p /var/www/ursinia

WWW=/var/www/ursinia

echo "Syncing website to install"
INSTALL_DIRS=""
for dir in src shared .well-known; do
	sudo rsync -avh --delete ./${dir} ${WWW}/${dir}
done

echo "Setting up nginx config as default"
sudo ln -s -f $(pwd)/nginx.default /etc/nginx/sites-enabled/default

