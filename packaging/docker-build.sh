#!/usr/bin/env bash

# Donot run this on local,
# this is supposed to be run inside docker

set -e
set -o pipefail

EXTRA_ADDONS_DIR="/opt/odoo/extraaddons"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    libtool \
    libjpeg-dev \
    zlib1g-dev
for dir in $EXTRA_ADDONS_DIR/*/; do
    if [[ -f ${dir}requirements.txt ]]; then
        pip install -r ${dir}requirements.txt
    fi
done
apt-get purge -y build-essential autoconf libtool
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists /var/cache/apt/archives

if [[ -f /etc/odoo/odoo.conf ]]; then
    rm /etc/odoo/odoo.conf
fi
