#!/bin/bash
# srv-render: NTP desde fw-vpn, SSH con LDAP (solo arquitectos y ti), intranet (nginx) y firewall.
# Necesita en /tmp: ntp-cliente.sh, setup-sssd.sh, setup-nginx.sh, intranet.html, nginx-intranet.conf,
#                   archivo.woff2, render-nftables.conf
set -euo pipefail
cd /tmp

echo "===== NTP"
bash /tmp/ntp-cliente.sh

echo "===== SSSD"
bash /tmp/setup-sssd.sh arquitectos,ti

echo "===== Intranet"
bash /tmp/setup-nginx.sh
cp /tmp/archivo.woff2 /var/www/intranet/archivo.woff2
curl -s -o /dev/null -w "fuente: HTTP %{http_code}\n" http://10.0.0.37/archivo.woff2

echo "===== Firewall"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq nftables >/dev/null
nft -c -f /tmp/render-nftables.conf
cp /tmp/render-nftables.conf /etc/nftables.conf
nft -f /etc/nftables.conf
systemctl enable nftables >/dev/null 2>&1
echo "reglas de entrada: $(nft list chain inet filtro input | grep -c accept) aceptaciones, política drop"
echo "===== listo"
