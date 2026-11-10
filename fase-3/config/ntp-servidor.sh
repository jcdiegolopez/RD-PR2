#!/bin/bash
# fw-vpn: servidor NTP para la red interna y la VPN
set -e
CONF=/etc/chrony/chrony.conf
sudo cp $CONF.orig $CONF
cat <<'EOF' | sudo tee -a $CONF >/dev/null

# Terranova: servidor NTP para los servidores y la VPN
allow 10.0.0.0/16
allow 10.10.1.0/24
EOF
sudo systemctl restart chrony
sleep 3
echo "--- fw-vpn: fuentes de hora"
chronyc sources | tail -2
echo "--- fw-vpn: puerto 123"
sudo ss -ulnp | grep ':123 '
