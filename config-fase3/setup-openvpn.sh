#!/bin/bash
# fw-vpn: 4 instancias de OpenVPN (una por grupo) con login de LDAP
set -e
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y -qq openvpn easy-rsa ldap-utils >/dev/null 2>&1
echo "paquetes ok: $(openvpn --version | head -1 | cut -d' ' -f1-2)"

S=/etc/openvpn/server
PKI=/etc/openvpn/easy-rsa
if [ ! -d $PKI/pki ]; then
  sudo rm -rf $PKI
  sudo make-cadir $PKI
  cd $PKI
  sudo EASYRSA_BATCH=1 ./easyrsa init-pki >/dev/null
  sudo EASYRSA_BATCH=1 EASYRSA_REQ_CN="Terranova CA" ./easyrsa build-ca nopass >/dev/null 2>&1
  sudo EASYRSA_BATCH=1 ./easyrsa build-server-full fw-vpn nopass >/dev/null 2>&1
  for c in cliente1 cliente2; do sudo EASYRSA_BATCH=1 ./easyrsa build-client-full $c nopass >/dev/null 2>&1; done
  sudo openvpn --genkey secret $S/ta.key
fi
cd $PKI
sudo cp pki/ca.crt $S/ca.crt
sudo cp pki/issued/fw-vpn.crt $S/fw-vpn.crt
sudo cp pki/private/fw-vpn.key $S/fw-vpn.key
sudo chmod 600 $S/fw-vpn.key $S/ta.key
echo "certificados ok"

sudo cp /tmp/ldap-auth.sh $S/ldap-auth.sh
sudo chmod 755 $S/ldap-auth.sh
sudo mkdir -p /var/log/openvpn /var/lib/openvpn

# nombre:puerto:red:mascara:grupo
for i in "arq:1194:10.10.1.0:255.255.255.224:arquitectos" \
         "ing:1195:10.10.1.32:255.255.255.240:ingenieros" \
         "ti:1196:10.10.1.48:255.255.255.248:ti" \
         "vis:1197:10.10.1.64:255.255.255.240:visitantes"; do
  IFS=: read n p red mask grupo <<< "$i"
  sudo touch /var/lib/openvpn/ipp-$n.txt
  sudo chown nobody:nogroup /var/lib/openvpn/ipp-$n.txt
  sudo tee $S/$n.conf >/dev/null <<EOF
# Terranova Â· instancia OpenVPN del grupo $grupo
port $p
proto udp
dev tun-$n
dev-type tun
topology subnet
server $red $mask
ca $S/ca.crt
cert $S/fw-vpn.crt
key $S/fw-vpn.key
dh none
tls-crypt $S/ta.key
ifconfig-pool-persist /var/lib/openvpn/ipp-$n.txt
status /var/log/openvpn/$n-status.log 10
push "redirect-gateway def1"
push "dhcp-option DNS 1.1.1.1"
script-security 2
auth-user-pass-verify "$S/ldap-auth.sh $grupo" via-file
username-as-common-name
keepalive 10 60
persist-key
persist-tun
user nobody
group nogroup
verb 3
EOF
done
echo "configuraciones ok"

for n in arq ing ti vis; do
  sudo systemctl enable --now openvpn-server@$n >/dev/null 2>&1 || true
done
sleep 3
for n in arq ing ti vis; do
  echo "--- openvpn-server@$n: $(systemctl is-active openvpn-server@$n)"
done
echo "--- interfaces"
ip -4 -br addr | grep tun || true
echo "--- puertos"
sudo ss -ulnp | grep openvpn || true
