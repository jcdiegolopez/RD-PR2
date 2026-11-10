#!/bin/bash
# SSH con usuarios de LDAP (SSSD) y endurecimiento de sshd. $1 = grupos permitidos (separados por coma)
set -e
GRUPOS="$1"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq sssd-ldap libpam-sss libnss-sss ldap-utils >/dev/null 2>&1
cat > /etc/sssd/sssd.conf <<EOF
[sssd]
services = nss, pam
domains = terranova

[domain/terranova]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://10.0.0.36
ldap_search_base = dc=terranova,dc=local
ldap_schema = rfc2307
ldap_auth_disable_tls_never_use_in_production = true
access_provider = simple
simple_allow_groups = $GRUPOS
cache_credentials = false
EOF
chmod 600 /etc/sssd/sssd.conf
pam-auth-update --enable mkhomedir >/dev/null
systemctl restart sssd
systemctl enable sssd >/dev/null 2>&1

cat > /etc/ssh/sshd_config.d/99-terranova.conf <<'EOF'
# Terranova: azureuser solo con llave; usuarios de LDAP con su clave
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
Match Group arquitectos,ingenieros,ti
    PasswordAuthentication yes
Match all
EOF
sshd -t
systemctl reload ssh
echo "--- $(hostname): usuarios de LDAP vistos por el sistema"
for u in ana.arq ivan.ing tomas.ti visita1; do id $u 2>&1; done
echo "--- grupos permitidos: $GRUPOS"
