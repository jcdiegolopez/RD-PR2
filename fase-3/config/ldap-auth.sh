#!/bin/bash
# Valida usuario y clave contra OpenLDAP y que sea del grupo de esta instancia.
# $1 = grupo requerido; $2 = archivo de OpenVPN con usuario (lÃ­nea 1) y clave (lÃ­nea 2)
GRUPO="$1"; ARCHIVO="$2"
BASE="dc=terranova,dc=local"; SERVIDOR="ldap://10.0.0.36"
USUARIO=$(sed -n 1p "$ARCHIVO")
[[ "$USUARIO" =~ ^[a-z0-9._-]+$ ]] || exit 1
CLAVE=$(mktemp); sed -n 2p "$ARCHIVO" | tr -d '\n' > "$CLAVE"
ldapwhoami -x -H "$SERVIDOR" -D "uid=$USUARIO,ou=usuarios,$BASE" -y "$CLAVE" >/dev/null 2>&1
OK=$?; rm -f "$CLAVE"
if [ "$OK" -ne 0 ]; then logger -t vpn-ldap "rechazado $USUARIO ($GRUPO): clave"; exit 1; fi
if ldapsearch -x -LLL -H "$SERVIDOR" -b "ou=grupos,$BASE" "(&(cn=$GRUPO)(memberUid=$USUARIO))" cn | grep -q "^cn: $GRUPO$"; then
  logger -t vpn-ldap "aceptado $USUARIO ($GRUPO)"; exit 0
fi
logger -t vpn-ldap "rechazado $USUARIO ($GRUPO): no es del grupo"; exit 1
