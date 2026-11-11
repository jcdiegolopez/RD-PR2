#!/bin/bash
# srv-planos: LDAP, NTP desde fw-vpn, SSH con usuarios de LDAP (SSSD) y firewall.
# Necesita en /tmp: setup-ldap.sh, claves.txt, ldap-admin.txt, ntp-cliente.sh, setup-sssd.sh, planos-nftables.conf
set -euo pipefail
cd /tmp

echo "===== LDAP"
LDAP_ADMIN_PW="$(cat /tmp/ldap-admin.txt)" bash /tmp/setup-ldap.sh /tmp/claves.txt

echo "===== NTP"
bash /tmp/ntp-cliente.sh

echo "===== SSSD"
bash /tmp/setup-sssd.sh arquitectos,ingenieros,ti

echo "===== Firewall"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq nftables >/dev/null
nft -c -f /tmp/planos-nftables.conf
cp /tmp/planos-nftables.conf /etc/nftables.conf
nft -f /etc/nftables.conf
systemctl enable nftables >/dev/null 2>&1
echo "reglas de entrada: $(nft list chain inet filtro input | grep -c accept) aceptaciones, política drop"

# Borrar las claves de /tmp
shred -u /tmp/claves.txt /tmp/ldap-admin.txt
echo "===== listo"
