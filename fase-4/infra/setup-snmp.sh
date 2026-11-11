#!/bin/bash
# SNMPv3 (autenticación SHA y cifrado AES) en una VM. Sin v1/v2c.
# Uso: sudo bash setup-snmp.sh <IP-privada-de-la-VM> /tmp/snmp.txt
# snmp.txt: dos líneas → clave de autenticación, clave de cifrado (mínimo 8 caracteres cada una)
set -euo pipefail
IP="${1:?Falta la IP privada}"
CLAVES="${2:?Falta el archivo de claves}"
AUTH=$(sed -n 1p "$CLAVES" | tr -d '\r'); PRIV=$(sed -n 2p "$CLAVES" | tr -d '\r')
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq snmpd snmp libsnmp-dev >/dev/null

systemctl stop snmpd
cat > /etc/snmp/snmpd.conf <<EOF
# Terranova · agente SNMP: solo v3, solo en la IP privada
agentaddress udp:$IP:161
sysLocation Azure North Central US · vnet-proyecto
sysContact ti@terranova.local
sysServices 72
includeAllDisks 10%
EOF
# Borra un usuario anterior con el mismo nombre para poder repetir el script
sed -i '/^usmUser .*"monitor"/d; /monitor/d' /var/lib/snmp/snmpd.conf 2>/dev/null || true
sed -i '/^rouser monitor/d' /usr/share/snmp/snmpd.conf 2>/dev/null || true
net-snmp-create-v3-user -ro -a SHA -A "$AUTH" -x AES -X "$PRIV" monitor >/dev/null
systemctl enable --now snmpd >/dev/null 2>&1
systemctl restart snmpd
sleep 1
echo "--- $(hostname): snmpd en $(ss -ulnp | grep -o "$IP:161" || echo 'NO ESCUCHA')"
shred -u "$CLAVES"
