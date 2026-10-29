#!/bin/bash
# Crea los NSG del proyecto y los asocia a las subredes de vnet-proyecto.
# Se ejecutó desde Azure Cloud Shell (bash) con la suscripción del proyecto activa:
#   az account set --subscription <SUBSCRIPTION-ID>
# Refleja el estado final (15 oct 2026): SSH a fw-vpn solo desde la IP del admin
# y sin reglas temporales (ver evidencia/07-cambios-azure.txt).
ADMIN_IP="<IP-ADMIN>/32"

set -f
RG=rg-redes-proyecto; VNET=vnet-proyecto
LOC=$(az network vnet show -g $RG -n $VNET --query location -o tsv); echo "Region de la red: $LOC"
SUB_FW=Firewall; SUB_DMZ=DMZ; SUB_SRV=Servidores

regla () {  # nsg prioridad nombre origen puertos protocolo accion [destino]
  az network nsg rule create -g $RG --nsg-name $1 --priority $2 -n $3 \
    --direction Inbound --source-address-prefixes $4 --source-port-ranges '*' \
    --destination-address-prefixes ${8:-*} --destination-port-ranges $5 \
    --protocol $6 --access $7 -o none && echo "ok   $1 $3"
}

for n in nsg-firewall nsg-dmz nsg-servidores; do
  az network nsg create -g $RG -n $n -l $LOC -o none && echo "creado $n"
done

# Subred Firewall (fw-vpn): VPN desde Internet, SSH solo del admin, servicios internos para la VNet y la VPN
regla nsg-firewall 100 Allow-OpenVPN     Internet 1194 Udp Allow
regla nsg-firewall 110 Allow-SSH-Admin   $ADMIN_IP 22  Tcp Allow
regla nsg-firewall 120 Allow-DNS-NTP     "10.0.0.0/16 10.10.0.0/16" "53 123" '*' Allow
regla nsg-firewall 130 Allow-ICMP        "10.0.0.0/16 10.10.0.0/16" '*' Icmp Allow
regla nsg-firewall 140 Allow-Retorno-VPN 10.0.0.0/16 '*' '*' Allow 10.10.0.0/16
regla nsg-firewall 4000 Deny-Resto       '*' '*' '*' Deny

# Subred DMZ (web): HTTP/HTTPS públicos y SSH solo interno
regla nsg-dmz 100 Allow-HTTP         Internet 80  Tcp Allow
regla nsg-dmz 110 Allow-HTTPS        Internet 443 Tcp Allow
regla nsg-dmz 120 Allow-SSH-Interno  "10.0.0.0/16 10.10.0.0/16" 22 Tcp Allow
regla nsg-dmz 130 Allow-ICMP         "10.0.0.0/16 10.10.0.0/16" '*' Icmp Allow
regla nsg-dmz 4000 Deny-Resto        '*' '*' '*' Deny

# Subred Servidores (srv-planos, srv-render): nada desde Internet
regla nsg-servidores 100 Allow-SSH        "10.0.0.0/16 10.10.0.0/16" 22 Tcp Allow
regla nsg-servidores 110 Allow-ICMP       "10.0.0.0/16 10.10.0.0/16" '*' Icmp Allow
regla nsg-servidores 120 Allow-SMB-Planos "10.10.1.0/27 10.10.1.32/28 10.10.1.48/29" 445 Tcp Allow   # Arquitectos, Ingenieros, TI
regla nsg-servidores 130 Allow-LDAP       "10.0.0.16/28 10.0.0.32/28" "389 636" Tcp Allow            # subredes Firewall y Servidores
regla nsg-servidores 4000 Deny-Resto      '*' '*' '*' Deny

az network vnet subnet update -g $RG --vnet-name $VNET -n $SUB_FW  --network-security-group nsg-firewall   -o none && echo "asociado $SUB_FW"
az network vnet subnet update -g $RG --vnet-name $VNET -n $SUB_DMZ --network-security-group nsg-dmz        -o none && echo "asociado $SUB_DMZ"
az network vnet subnet update -g $RG --vnet-name $VNET -n $SUB_SRV --network-security-group nsg-servidores -o none && echo "asociado $SUB_SRV"
set +f
