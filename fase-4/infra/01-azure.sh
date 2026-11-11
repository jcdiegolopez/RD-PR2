#!/bin/bash
# Crea toda la red de Terranova en una suscripción nueva (Fase 3 + Fase 4):
# grupo de recursos, VNet, subredes, NSG, tablas de rutas, IP pública y las 4 VMs.
#
# Uso (Azure Cloud Shell en bash, o Git Bash con az instalado):
#   az account set --subscription <ID-DE-LA-SUSCRIPCION-NUEVA>
#   ADMIN_IP=<tu-ip-publica> SSH_PUB=~/.ssh/terranova.pub bash 01-azure.sh
#
# Se puede correr dos veces: lo que ya existe se actualiza o se salta.
set -euo pipefail
set -f   # sin expansión de '*' en las reglas

: "${ADMIN_IP:?Falta ADMIN_IP (IP pública desde donde se administra fw-vpn)}"
: "${SSH_PUB:?Falta SSH_PUB (ruta de la llave pública SSH para azureuser)}"
LOC="${LOC:-northcentralus}"
RG="${RG:-rg-redes-proyecto}"
VNET=vnet-proyecto

echo "== Suscripción: $(az account show --query name -o tsv) · región $LOC"

# ---------- Cuota: hacen falta 8 vCPU ----------
LIM=$(az vm list-usage -l "$LOC" --query "[?name.value=='cores'].limit | [0]" -o tsv)
echo "== Cuota regional de vCPU: $LIM (hacen falta 8)"
if [ "${LIM:-0}" -lt 8 ]; then echo "La cuota no alcanza. Pedir 8 en Portal → Quotas antes de seguir."; exit 1; fi

# ---------- Grupo de recursos, VNet y subredes ----------
az group create -n "$RG" -l "$LOC" -o none && echo "ok   grupo $RG"
az network vnet create -g "$RG" -n $VNET -l "$LOC" --address-prefixes 10.0.0.0/16 -o none && echo "ok   $VNET"
for s in "DMZ 10.0.0.0/28" "Firewall 10.0.0.16/28" "Servidores 10.0.0.32/28"; do
  set -- $s
  az network vnet subnet create -g "$RG" --vnet-name $VNET -n "$1" --address-prefixes "$2" -o none && echo "ok   subred $1 $2"
done

# ---------- NSG ----------
regla () {  # nsg dirección prioridad nombre origen destino puertos protocolo acción
  az network nsg rule create -g "$RG" --nsg-name "$1" --direction "$2" --priority "$3" -n "$4" \
    --source-address-prefixes $5 --source-port-ranges '*' \
    --destination-address-prefixes $6 --destination-port-ranges $7 \
    --protocol "$8" --access "$9" -o none && echo "ok   $1 $4"
}
for n in nsg-firewall nsg-dmz nsg-servidores; do
  az network nsg create -g "$RG" -n $n -l "$LOC" -o none && echo "ok   $n"
done

# Subred Firewall (fw-vpn). Este NSG también filtra lo que fw-vpn reenvía (lección de la Fase 3).
regla nsg-firewall Inbound  100 Allow-OpenVPN          Internet                    '*'          1194-1197 Udp  Allow
regla nsg-firewall Inbound  105 Allow-Web-Publico      Internet                    '*'          "80 443"  Tcp  Allow
regla nsg-firewall Inbound  110 Allow-SSH-Admin        "$ADMIN_IP/32"              '*'          22        Tcp  Allow
regla nsg-firewall Inbound  120 Allow-DNS-NTP          "10.0.0.0/16 10.10.0.0/16"  '*'          "53 123"  '*'  Allow
regla nsg-firewall Inbound  130 Allow-ICMP             "10.0.0.0/16 10.10.0.0/16"  '*'          '*'       Icmp Allow
regla nsg-firewall Inbound  140 Allow-Retorno-VPN      10.0.0.0/16                 10.10.0.0/16 '*'       '*'  Allow
regla nsg-firewall Inbound  150 Allow-Salida-Internos  "10.0.0.32/28 10.0.0.0/28"  '*'          '*'       '*'  Allow
regla nsg-firewall Inbound  155 Allow-SNMP-Colector    10.0.0.36                   '*'          161       Udp  Allow
regla nsg-firewall Inbound  4000 Deny-Resto            '*'                         '*'          '*'       '*'  Deny
regla nsg-firewall Outbound 100 Allow-VPN-Hacia-Red    10.10.1.0/24                10.0.0.0/16  '*'       '*'  Allow
regla nsg-firewall Outbound 110 Allow-DNAT-Web         '*'                         10.0.0.4     "80 443"  Tcp  Allow

# Subred DMZ (srv-web): la web para todos; SSH, ICMP y SNMP solo de adentro
regla nsg-dmz Inbound 100 Allow-Web            '*'                       10.0.0.4 "80 443" Tcp  Allow
regla nsg-dmz Inbound 110 Allow-SSH-Admin-TI   "10.0.0.20 10.10.1.48/29" 10.0.0.4 22       Tcp  Allow
regla nsg-dmz Inbound 120 Allow-SNMP-Colector  10.0.0.36                 10.0.0.4 161      Udp  Allow
regla nsg-dmz Inbound 130 Allow-ICMP-TI        "10.0.0.20 10.10.1.48/29" 10.0.0.4 '*'      Icmp Allow
regla nsg-dmz Inbound 4000 Deny-Resto          '*'                       '*'      '*'      '*'  Deny

# Subred Servidores: reglas por grupo (caso 4). La DMZ y Visitantes no aparecen en ninguna.
INTERNOS="10.0.0.16/28 10.0.0.32/28"
regla nsg-servidores Inbound 100 Allow-TI-Todo        10.10.1.48/29                                '*'       '*'       '*'  Allow
regla nsg-servidores Inbound 105 Allow-SSH-Planos     "10.0.0.20 10.10.1.0/27 10.10.1.32/28"       10.0.0.36 22        Tcp  Allow
regla nsg-servidores Inbound 110 Allow-SSH-Render     "10.0.0.20 10.0.0.36 10.10.1.0/27"           10.0.0.37 22        Tcp  Allow
regla nsg-servidores Inbound 125 Allow-Web-Intranet   "$INTERNOS 10.10.1.0/27 10.10.1.32/28"       10.0.0.37 80        Tcp  Allow
regla nsg-servidores Inbound 130 Allow-LDAP           "$INTERNOS"                                  10.0.0.36 "389 636" Tcp  Allow
regla nsg-servidores Inbound 140 Allow-ICMP           "$INTERNOS 10.10.1.0/27 10.10.1.32/28"       '*'       '*'       Icmp Allow
regla nsg-servidores Inbound 145 Allow-NFS-Renders    10.0.0.37                                    10.0.0.36 2049      Tcp  Allow
regla nsg-servidores Inbound 150 Allow-SNMP-Colector  10.0.0.36                                    10.0.0.37 161       Udp  Allow
regla nsg-servidores Inbound 4000 Deny-Resto          '*'                                          '*'       '*'       '*'  Deny

# ---------- Tablas de rutas ----------
ruta () {  # tabla nombre destino
  az network route-table route create -g "$RG" --route-table-name "$1" -n "$2" --address-prefix "$3" \
    --next-hop-type VirtualAppliance --next-hop-ip-address 10.0.0.20 -o none && echo "ok   $1 $2 $3 → 10.0.0.20"
}
for t in rt-servidores rt-dmz; do az network route-table create -g "$RG" -n $t -l "$LOC" -o none && echo "ok   $t"; done
ruta rt-servidores vpn-hacia-fw        10.10.0.0/16
ruta rt-servidores internet-hacia-fw   0.0.0.0/0
ruta rt-servidores dmz-hacia-fw        10.0.0.0/28
ruta rt-dmz        internet-hacia-fw   0.0.0.0/0
ruta rt-dmz        vpn-hacia-fw        10.10.0.0/16
ruta rt-dmz        servidores-hacia-fw 10.0.0.32/28

# ---------- Asociar NSG y rutas a las subredes (Firewall nunca lleva tabla de rutas) ----------
az network vnet subnet update -g "$RG" --vnet-name $VNET -n Firewall   --network-security-group nsg-firewall -o none
az network vnet subnet update -g "$RG" --vnet-name $VNET -n DMZ        --network-security-group nsg-dmz        --route-table rt-dmz        -o none
az network vnet subnet update -g "$RG" --vnet-name $VNET -n Servidores --network-security-group nsg-servidores --route-table rt-servidores -o none
echo "ok   NSG y rutas asociados"

# ---------- fw-vpn: IP pública estática y NIC con IP forwarding ----------
az network public-ip create -g "$RG" -n fw-vpn-ip -l "$LOC" --sku Standard --allocation-method Static -o none
az network nic create -g "$RG" -n fw-vpn-nic -l "$LOC" --vnet-name $VNET --subnet Firewall \
  --private-ip-address 10.0.0.20 --public-ip-address fw-vpn-ip --ip-forwarding true -o none
echo "ok   fw-vpn-ip y fw-vpn-nic (IP forwarding activo)"

# ---------- VMs ----------
az vm create -g "$RG" -n fw-vpn -l "$LOC" --image Ubuntu2404 --size Standard_B2ats_v2 \
  --nics fw-vpn-nic --admin-username azureuser --ssh-key-values "$SSH_PUB" -o none && echo "ok   fw-vpn"

vm () {  # nombre subred ip tamaño imagen
  az vm create -g "$RG" -n "$1" -l "$LOC" --image "$5" --size "$4" \
    --vnet-name $VNET --subnet "$2" --private-ip-address "$3" \
    --public-ip-address "" --nsg "" \
    --admin-username azureuser --ssh-key-values "$SSH_PUB" -o none && echo "ok   $1 $3"
}
vm srv-planos Servidores 10.0.0.36 Standard_B2als_v2 Ubuntu2204
vm srv-render Servidores 10.0.0.37 Standard_B2als_v2 Ubuntu2204
vm srv-web    DMZ        10.0.0.4  Standard_B2ats_v2 Ubuntu2204

# ---------- Resumen ----------
IP=$(az network public-ip show -g "$RG" -n fw-vpn-ip --query ipAddress -o tsv)
echo
echo "== Listo. IP pública de fw-vpn: $IP"
echo "   - Apuntar el dominio (registros A @ y www) a $IP"
echo "   - Poner $IP en los perfiles .ovpn y en fase-4/config/fw-nftables.conf (DNAT desde la VPN)"
echo "   - Entrar: ssh azureuser@$IP   ·   a los servidores: ssh -J azureuser@$IP azureuser@10.0.0.36"
az vm list -g "$RG" -d --query "[].{vm:name, ip:privateIps, tam:hardwareProfile.vmSize, estado:powerState}" -o table
set +f
