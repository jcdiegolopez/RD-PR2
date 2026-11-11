#!/bin/bash
# fw-vpn: reenvío de paquetes, firewall (nftables con red de rescate), NTP (chrony) y DNS interno (BIND9).
# Uso: copiar a /tmp este script, fw-nftables.conf (ya con <IP-ADMIN> y <IP-PUBLICA-FW> reemplazados)
#      y la zona db.terranova.local; luego: sudo bash /tmp/setup-fw-base.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "== reenvío de paquetes"
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-terranova.conf
sysctl --system >/dev/null
sysctl net.ipv4.ip_forward

echo "== paquetes"
apt-get update -qq >/dev/null
apt-get install -y -qq nftables chrony bind9 bind9-dnsutils >/dev/null
echo "ok"

echo "== firewall (si se pierde el SSH, se borra solo en 5 minutos)"
nft -c -f /tmp/fw-nftables.conf
cp /tmp/fw-nftables.conf /etc/nftables.conf
systemctl stop nft-rescate.timer 2>/dev/null || true
systemd-run --quiet --unit=nft-rescate --on-active=300 /usr/sbin/nft flush ruleset
nft -f /etc/nftables.conf
echo "reglas aplicadas; rescate programado (cancelar con: systemctl stop nft-rescate.timer)"

echo "== NTP: servidor para la red y la VPN"
CONF=/etc/chrony/chrony.conf
cp -n $CONF $CONF.orig
cp $CONF.orig $CONF
cat >> $CONF <<'EOF'

# Terranova: servidor NTP para los servidores y la VPN
allow 10.0.0.0/16
allow 10.10.1.0/24
EOF
systemctl restart chrony
systemctl enable chrony >/dev/null 2>&1

echo "== DNS interno: BIND9 con la zona terranova.local"
cat > /etc/bind/named.conf.options <<'EOF'
acl internos { 127.0.0.1; 10.0.0.0/16; 10.10.1.0/27; 10.10.1.32/28; 10.10.1.48/29; };
options {
  directory "/var/cache/bind";
  listen-on { any; };
  listen-on-v6 { none; };
  allow-query { internos; };
  allow-recursion { internos; };
  forwarders { 168.63.129.16; };
  forward only;
  dnssec-validation auto;
};
EOF
cat > /etc/bind/named.conf.local <<'EOF'
zone "terranova.local" { type master; file "/etc/bind/db.terranova.local"; };
EOF
cp /tmp/db.terranova.local /etc/bind/db.terranova.local
named-checkconf
named-checkzone terranova.local /etc/bind/db.terranova.local
systemctl restart named
systemctl enable named >/dev/null 2>&1
sleep 2
echo "--- puerto 53"
ss -lunp | grep ':53 ' || true
echo "--- prueba: planos.terranova.local"
dig +short @10.0.0.20 planos.terranova.local
dig +short @10.0.0.20 intranet.terranova.local
echo "--- prueba: nombre externo (reenviado a Azure)"
dig +short @10.0.0.20 ubuntu.com | head -2
