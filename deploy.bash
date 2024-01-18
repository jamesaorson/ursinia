#! /bin/sh

set -eu

sudo mkdir -p /var/www/ursinia

WWW=/var/www/ursinia

echo "Syncing website to install"
INSTALL_DIRS=""
for dir in src shared; do
	sudo rsync -avh --delete ./src ${WWW}/${dir}
done

