#!/bin/bash
# Crea un usuario de la VPN: certificado, IP fija (ccd) y archivo .ovpn.
# Uso: ./nuevo-cliente.sh <usuario> <ip>
#   ./nuevo-cliente.sh arq01 10.10.1.1     # Arquitectos 10.10.1.0/27
#   ./nuevo-cliente.sh ing01 10.10.1.33    # Ingenieros  10.10.1.32/28
#   ./nuevo-cliente.sh ti01  10.10.1.49    # TI          10.10.1.48/29
set -e
NOMBRE=$1; IP=$2
cd ~/easy-rsa
./easyrsa --batch build-client-full "$NOMBRE" nopass
echo "ifconfig-push $IP 255.255.254.0" | sudo tee /etc/openvpn/server/ccd/$NOMBRE > /dev/null
mkdir -p ~/clientes
{
  cat ~/client-base.conf
  echo "<ca>";   cat pki/ca.crt; echo "</ca>"
  echo "<cert>"; sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' pki/issued/$NOMBRE.crt; echo "</cert>"
  echo "<key>";  cat pki/private/$NOMBRE.key; echo "</key>"
  echo "<tls-crypt>"; sudo cat /etc/openvpn/server/tc.key; echo "</tls-crypt>"
} > ~/clientes/$NOMBRE.ovpn
echo "Listo: ~/clientes/$NOMBRE.ovpn  ->  $IP"
