#!/bin/bash
# Imprime un perfil .ovpn. $1 = puerto, $2 = cliente (cliente1 o cliente2), $3 = grupo
P=/etc/openvpn/easy-rsa/pki
cat <<EOF
# Terranova Â· VPN del grupo $3
client
dev tun
proto udp
remote <IP-PUBLICA-FW-VPN> $1
nobind
persist-key
persist-tun
remote-cert-tls server
auth-user-pass
auth-nocache
verb 3
<ca>
$(cat $P/ca.crt)
</ca>
<cert>
$(openssl x509 -in $P/issued/$2.crt)
</cert>
<key>
$(cat $P/private/$2.key)
</key>
<tls-crypt>
$(cat /etc/openvpn/server/ta.key)
</tls-crypt>
EOF
