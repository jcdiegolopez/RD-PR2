#!/bin/bash
# srv-planos: OpenLDAP igual al de la Fase 3 (exportado con slapcat el 10 nov 2026,
# referencia en ldap-referencia.ldif): base dc=terranova,dc=local, 4 grupos posix y 4 usuarios.
#
# Uso:  sudo LDAP_ADMIN_PW='<clave-admin>' bash setup-ldap.sh claves.txt
# claves.txt: una línea por usuario → "uid clave"
#   ana.arq <clave>
#   ivan.ing <clave>
#   tomas.ti <clave>
#   visita1 <clave>
set -euo pipefail
: "${LDAP_ADMIN_PW:?Falta LDAP_ADMIN_PW}"
CLAVES="${1:?Falta el archivo de claves}"
BASE="dc=terranova,dc=local"
ADMIN="cn=admin,$BASE"
export DEBIAN_FRONTEND=noninteractive

# ---------- slapd sin preguntas (dominio terranova.local, organización Terranova) ----------
debconf-set-selections <<EOF
slapd slapd/no_configuration boolean false
slapd slapd/domain string terranova.local
slapd shared/organization string Terranova
slapd slapd/password1 password $LDAP_ADMIN_PW
slapd slapd/password2 password $LDAP_ADMIN_PW
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
EOF
apt-get update -qq >/dev/null
apt-get install -y -qq slapd ldap-utils >/dev/null
dpkg-reconfigure -f noninteractive slapd >/dev/null 2>&1
echo "slapd ok: $(dpkg -l slapd | awk '/^ii/{print $3}')"

# ---------- Índices (los mismos de la Fase 3; uidNumber/gidNumber aceleran SSSD) ----------
ldapmodify -Q -Y EXTERNAL -H ldapi:/// >/dev/null <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcDbIndex
olcDbIndex: objectClass eq
olcDbIndex: cn,uid eq
olcDbIndex: uidNumber,gidNumber eq
olcDbIndex: member,memberUid eq
EOF
echo "índices ok"

# ---------- Usuarios y grupos ----------
clave () { awk -v u="$1" '$1==u {print $2}' "$CLAVES"; }
hash ()  { local c; c=$(clave "$1"); [ -n "$c" ] || { echo "Falta la clave de $1 en $CLAVES" >&2; exit 1; }; slappasswd -s "$c"; }

# uid · nombre · apellido · uidNumber · grupo · gidNumber
USUARIOS="ana.arq   Ana    Arquitecta 10001 arquitectos 20001
ivan.ing  Ivan   Ingeniero  10002 ingenieros  20002
tomas.ti  Tomas  TI         10003 ti          20003
visita1   Visita Uno        10004 visitantes  20004"

LDIF=$(mktemp)
cat > "$LDIF" <<EOF
dn: ou=usuarios,$BASE
objectClass: organizationalUnit
ou: usuarios

dn: ou=grupos,$BASE
objectClass: organizationalUnit
ou: grupos

EOF
while read -r uid nombre apellido uidn grupo gidn; do
  cat >> "$LDIF" <<EOF
dn: uid=$uid,ou=usuarios,$BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $uid
cn: $nombre $apellido
givenName: $nombre
sn: $apellido
uidNumber: $uidn
gidNumber: $gidn
homeDirectory: /home/$uid
loginShell: /bin/bash
userPassword: $(hash "$uid")

dn: cn=$grupo,ou=grupos,$BASE
objectClass: posixGroup
cn: $grupo
gidNumber: $gidn
memberUid: $uid

EOF
done <<< "$USUARIOS"

ldapadd -x -D "$ADMIN" -w "$LDAP_ADMIN_PW" -f "$LDIF" >/dev/null
rm -f "$LDIF"

# ---------- Verificación ----------
echo "--- grupos"
ldapsearch -x -LLL -b "ou=grupos,$BASE" "(objectClass=posixGroup)" cn gidNumber memberUid
echo "--- usuarios"
ldapsearch -x -LLL -b "ou=usuarios,$BASE" "(objectClass=posixAccount)" uid cn uidNumber gidNumber
echo "--- login de prueba (ana.arq)"
ldapwhoami -x -D "uid=ana.arq,ou=usuarios,$BASE" -w "$(clave ana.arq)"
echo "--- escuchando"
ss -tlnp | grep slapd
