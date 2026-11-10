#!/bin/bash
# Servidores: sincronizar la hora solo con fw-vpn (10.0.0.20)
set -e
CONF=/etc/chrony/chrony.conf
sudo cp -n $CONF $CONF.orig
sudo sed -i -E 's/^(pool |server |refclock )/# &/' $CONF
grep -q '^server 10.0.0.20' $CONF || echo 'server 10.0.0.20 iburst prefer' | sudo tee -a $CONF >/dev/null
sudo systemctl restart chrony
sleep 20
echo "--- $(hostname): fuentes de hora"
chronyc sources -v | tail -4
chronyc tracking | head -4
