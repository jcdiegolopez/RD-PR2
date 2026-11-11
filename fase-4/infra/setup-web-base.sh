#!/bin/bash
# srv-web (DMZ): nginx para la página pública, NTP desde fw-vpn, DNS interno dividido,
# firewall y SSH solo con llave. Sin LDAP: es un servidor público.
# Necesita en /tmp: ntp-cliente.sh, web-nftables.conf, nginx-terranova.conf y la carpeta web/ (index.html, ...)
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "===== paquetes"
apt-get update -qq >/dev/null
apt-get install -y -qq nginx nftables >/dev/null
echo ok

echo "===== página pública"
mkdir -p /var/www/terranova
cp -r /tmp/web/. /var/www/terranova/
cp /tmp/nginx-terranova.conf /etc/nginx/sites-available/terranova
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/terranova /etc/nginx/sites-enabled/terranova
sed -i 's/# *server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
nginx -t 2>&1 | tail -1
systemctl restart nginx && systemctl enable nginx >/dev/null 2>&1
curl -s http://127.0.0.1 | grep -o '<title>.*</title>'

echo "===== NTP"
bash /tmp/ntp-cliente.sh | tail -3

echo "===== DNS interno (solo terranova.local va a fw-vpn)"
mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nDNS=10.0.0.20\nDomains=~terranova.local\n' > /etc/systemd/resolved.conf.d/terranova.conf
systemctl restart systemd-resolved
getent hosts planos.terranova.local || echo "no resuelve"

echo "===== SSH: sin root, solo llave"
printf 'PermitRootLogin no\nPasswordAuthentication no\nKbdInteractiveAuthentication no\n' > /etc/ssh/sshd_config.d/99-terranova.conf
sshd -t && systemctl reload ssh
sshd -T | grep -E '^(permitrootlogin|passwordauthentication) '

echo "===== firewall"
nft -c -f /tmp/web-nftables.conf
cp /tmp/web-nftables.conf /etc/nftables.conf
nft -f /etc/nftables.conf
systemctl enable nftables >/dev/null 2>&1
echo "reglas de entrada: $(nft list chain inet filtro input | grep -c accept) aceptaciones, política drop"
echo "===== listo"
