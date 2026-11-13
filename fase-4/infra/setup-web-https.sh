#!/bin/bash
# srv-web: publica la página de fase-4/web/, pone el dominio en nginx y saca el certificado HTTPS (Let's Encrypt).
# Uso: sudo bash setup-web-https.sh <dominio>
# Necesita en /tmp: la carpeta web/ (página completa) y nginx-terranova.conf con el dominio ya puesto.
# Antes: el dominio debe resolver a la IP pública de fw-vpn y el DNAT (80/443) debe estar activo.
set -euo pipefail
DOMINIO="${1:?Falta el dominio}"
export DEBIAN_FRONTEND=noninteractive

echo "===== página"
rm -rf /var/www/terranova/*
cp -r /tmp/web/. /var/www/terranova/
chown -R root:root /var/www/terranova
find /var/www/terranova -type d -exec chmod 755 {} \; ; find /var/www/terranova -type f -exec chmod 644 {} \;
find /var/www/terranova -type f | sed 's#/var/www/terranova/##' | sort

echo "===== nginx con el dominio"
cp /tmp/nginx-terranova.conf /etc/nginx/sites-available/terranova
nginx -t 2>&1 | tail -1
systemctl reload nginx
curl -s -H "Host: $DOMINIO" http://127.0.0.1 | grep -o '<title>.*</title>'

echo "===== certbot"
apt-get update -qq >/dev/null
apt-get install -y -qq certbot python3-certbot-nginx >/dev/null
certbot --version

echo "===== prueba en seco (servidor de pruebas de Let's Encrypt)"
certbot certonly --nginx --dry-run -d "$DOMINIO" -d "www.$DOMINIO" --register-unsafely-without-email --agree-tos -n 2>&1 | tail -6

echo "===== certificado real, con redirección de HTTP a HTTPS"
certbot --nginx -d "$DOMINIO" -d "www.$DOMINIO" --redirect --register-unsafely-without-email --agree-tos -n 2>&1 | tail -12

echo "===== resultado"
nginx -t 2>&1 | tail -1
ss -tlnp | grep -E ':(80|443) ' | awk '{print $4}'
certbot certificates 2>/dev/null | grep -E 'Certificate Name|Domains|Expiry'
systemctl list-timers 2>/dev/null | grep -i certbot | head -1 || true
