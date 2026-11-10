#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y -qq nginx >/dev/null 2>&1
sudo mkdir -p /var/www/intranet
sudo cp /tmp/intranet.html /var/www/intranet/index.html
sudo cp /tmp/nginx-intranet.conf /etc/nginx/sites-available/intranet
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/intranet /etc/nginx/sites-enabled/intranet
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx >/dev/null 2>&1
echo "--- puertos de nginx"
sudo ss -tlnp | grep nginx
echo "--- prueba local"
curl -s http://10.0.0.37 | grep -o "<title>.*</title>"
