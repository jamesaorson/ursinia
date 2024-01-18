#! /bin/sh

set -eu

sudo mkdir -p /var/www/ursinia

WWW=/var/www/ursinia

echo "Syncing website to install"
for dir in src shared .well-known; do
	mkdir -p ${WWW}/${dir}
	sudo rsync -avh --delete ./${dir}/ ${WWW}/${dir}
done

echo "Setting up nginx config as default"
sudo ln -s -f $(pwd)/nginx.default /etc/nginx/sites-enabled/default

echo "Restarting nginx"
sudo systemctl restart nginx
echo "Checking nginx"
sudo systemctl status nginx
