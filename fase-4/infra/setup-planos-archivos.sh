#!/bin/bash
# srv-planos: carpeta de planos y renders con permisos por grupo de LDAP, y NFS para srv-render.
# Arquitectos: lectura y escritura · Ingenieros: solo lectura · TI: todo · Visitantes: nada.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq acl nfs-kernel-server >/dev/null

mkdir -p /srv/planos/proyectos /srv/planos/renders/escenas /srv/planos/renders/salida
chgrp -R arquitectos /srv/planos
chmod -R 2770 /srv/planos
setfacl -R -m g:ingenieros:rx -m d:g:ingenieros:rx /srv/planos
setfacl -R -m g:ti:rwx -m d:g:ti:rwx /srv/planos
for p in "Torre Aurora" "Residencial Vista Norte" "Condominio Los Robles"; do mkdir -p "/srv/planos/proyectos/$p"; done
chgrp -R arquitectos /srv/planos/proyectos; chmod -R 2770 /srv/planos/proyectos

cat > /etc/exports <<'EOF'
# Terranova: srv-render guarda los renders aquí (NFSv4, mismos uid/gid por LDAP)
/srv/planos/renders 10.0.0.37(rw,sync,root_squash,no_subtree_check)
EOF
exportfs -ra
systemctl enable --now nfs-server >/dev/null 2>&1
echo "--- exportado"; exportfs -v
echo "--- permisos"; getfacl -p /srv/planos 2>/dev/null | grep -E '^(group|default:group)'
ls -la /srv/planos /srv/planos/proyectos
