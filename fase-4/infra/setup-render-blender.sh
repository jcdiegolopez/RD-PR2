#!/bin/bash
# srv-render: monta la carpeta de renders de srv-planos por NFS, instala Blender y hace un render de prueba
# como ana.arq (arquitectos). Necesita /tmp/render-casa.py.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq nfs-common >/dev/null

echo "===== NFS"
mkdir -p /srv/renders
grep -q '/srv/renders' /etc/fstab || echo 'planos.terranova.local:/srv/planos/renders /srv/renders nfs4 defaults,_netdev 0 0' >> /etc/fstab
mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nDNS=10.0.0.20\nDomains=~terranova.local\n' > /etc/systemd/resolved.conf.d/terranova.conf
systemctl restart systemd-resolved
systemctl daemon-reload
mount -a
findmnt /srv/renders

echo "===== Blender"
# El paquete apt de Ubuntu viene sin la carpeta colormanagement y los renders salen negros:
# se usa el snap oficial de la Blender Foundation.
apt-get purge -y -qq blender blender-data >/dev/null 2>&1 || true
snap list blender >/dev/null 2>&1 || snap install blender --classic >/dev/null
# Librerías gráficas que el binario oficial toma del sistema (no hace falta pantalla)
apt-get install -y -qq libsm6 libice6 libxi6 libxxf86vm1 libxfixes3 libxrender1 libxext6 libx11-6 libxkbcommon0 libgl1 libegl1 >/dev/null
# El lanzador de snap necesita una carpeta personal real en /home
mkdir -p /home/ana.arq && chown ana.arq:arquitectos /home/ana.arq && chmod 700 /home/ana.arq
sudo -u ana.arq -H /snap/bin/blender --version 2>/dev/null | head -1 || true

echo "===== Render de prueba (como ana.arq, con prioridad baja)"
cp /tmp/render-casa.py /srv/renders/escenas/render-casa.py 2>/dev/null || sudo -u ana.arq cp /tmp/render-casa.py /srv/renders/escenas/
START=$(date +%s)
sudo -u ana.arq -H nice -n 19 /snap/bin/blender -b -P /tmp/render-casa.py -- \
  /srv/renders/salida/condominio_0001.png /srv/renders/escenas/condominio.blend 2>&1 | grep -E 'RENDER LISTO|Error' || true
echo "tiempo: $(( $(date +%s) - START )) s"
sudo -u ana.arq ls -la /srv/renders/salida
