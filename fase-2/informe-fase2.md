# Proyecto Final, Fase 2 · Implementación de la red en Azure: segmentación y conectividad

> Copia en texto del informe de Google Docs (exportada el 10 nov 2026). **No incluye las figuras**: están en el original. Original: https://docs.google.com/document/d/1Z12l6kziRNfVFDvcDO3smcxcoiQEAhsEfKDNzsBdjXw/edit
>
> Se copió tal como estaba, incluidas las notas de edición pendientes entre corchetes.

Informe de avance del Caso 4: desarrolladora de bienes raíces.
Curso: Redes de Computadoras 2026 (CC3067, Sección 30). Docente: Juan Carlos Canteo Boix.
Integrantes: Jose Pablo, Joel Jaquez, Diego López, Erick Guerra, Diego Rosales, Fabian Morales. Octubre de 2026.

## Repositorio

https://github.com/jcdiegolopez/RD-PR2

## Resumen ejecutivo

Este informe documenta la implementación de la Fase 2 del Caso 4 (desarrolladora de bienes raíces) sobre Microsoft Azure con la cuenta Azure for Students. Se desplegó la red virtual vnet-proyecto (10.0.0.0/16) con tres subredes /28 (DMZ, Firewall y Servidores), se calcularon las subredes de los departamentos con VLSM y se demostró conectividad por ping y SSH entre dos instancias de la misma subred (srv-planos y srv-render), en ambos sentidos, y entre subredes desde fw-vpn. Lo que queda como diseño (NAT, rutas, OpenVPN, ACL, VM web) está indicado en cada sección.

## 1. Plataforma, cuenta y región

La implementación se hizo en Microsoft Azure con la suscripción Azure for Students de la cuenta institucional de uno de los integrantes. El resto del grupo trabaja sobre el grupo de recursos rg-redes-proyecto con el rol Contributor (o Owner), asignado desde Control de acceso (IAM). Todos los recursos viven en esa suscripción, y por eso el crédito de $100 se consume de una sola cuenta.

La región es North Central US. La Fase 1 estimaba costos para Sweden Central, pero la suscripción tiene la política Allowed resource deployment regions, que solo permite Norway East, France Central, Belgium Central, Canada Central y North Central US. El intento de crear la red en Sweden Central falló con RequestDisallowedByPolicy. Se eligió North Central US por ser la más cercana a Guatemala.

## 2. Segmentación de la red

El direccionamiento sigue el esquema VLSM de la Fase 1: cada subred tiene el tamaño que necesita. La red virtual usa 10.0.0.0/16, y los departamentos reciben su IP dentro del bloque de la VPN, 10.10.0.0/23.

| Subred | Ubicación | Rango | Máscara | Equipos |
|---|---|---|---|---|
| DMZ | Azure | 10.0.0.0/28 | 255.255.255.240 | web 10.0.0.4 (diseñada) |
| Firewall | Azure | 10.0.0.16/28 | 255.255.255.240 | fw-vpn 10.0.0.20 |
| Servidores | Azure | 10.0.0.32/28 | 255.255.255.240 | srv-planos 10.0.0.36, srv-render 10.0.0.37 |
| Arquitectos (15) | VPN | 10.10.1.0/27 | 255.255.255.224 | IP asignada por OpenVPN |
| Ingenieros (10) | VPN | 10.10.1.32/28 | 255.255.255.240 | IP asignada por OpenVPN |
| TI (3) | VPN | 10.10.1.48/29 | 255.255.255.248 | IP asignada por OpenVPN |

*Figura 1. Configuración IP de la tarjeta de red de srv-planos: vnet-proyecto, subred Servidores (10.0.0.32/28) y IP privada estática 10.0.0.36.*

## 3. Cálculos de subnetting

### Método

Para N hosts se busca el menor número de bits de host n tal que 2^n − 2 ≥ N. Con n bits de host, la máscara es /(32 − n), el bloque tiene 2^n direcciones, la primera es la dirección de red y la última es el broadcast. En Azure, cada subred reserva 5 direcciones (red, router, dos de DNS y broadcast), así que las usables son 2^n − 5.

### Departamentos (rangos dentro de la VPN)

| Departamento | Personas | Bits de host | Máscara | Red | Rango usable | Broadcast |
|---|---|---|---|---|---|---|
| Arquitectos | 15 | 5 (2⁵ − 2 = 30 ≥ 15) | /27 = 255.255.255.224 | 10.10.1.0 | .1 a .30 | 10.10.1.31 |
| Ingenieros | 10 | 4 (2⁴ − 2 = 14 ≥ 10) | /28 = 255.255.255.240 | 10.10.1.32 | .33 a .46 | 10.10.1.47 |
| TI | 3 | 3 (2³ − 2 = 6 ≥ 3) | /29 = 255.255.255.248 | 10.10.1.48 | .49 a .54 | 10.10.1.55 |

Según el diagrama de la Fase 1, el pool de OpenVPN entrega a Arquitectos las IP .1 a .15, a Ingenieros .33 a .42 y a TI .49 a .51 (el número exacto de personas de cada grupo); el resto del bloque queda de reserva para crecer.

Por qué no un bloque más pequeño: un /28 solo da 14 usables y no alcanza para 15 arquitectos; un /30 solo da 2 y no alcanza para 3 personas de TI.

### Subredes en Azure

| Subred | Rango | Direcciones | Reservadas por Azure | Usables | Rango usable |
|---|---|---|---|---|---|
| DMZ | 10.0.0.0/28 | 16 | 5 (.0 red, .1 router, .2 y .3 DNS, .15 broadcast) | 11 | 10.0.0.4 a 10.0.0.14 |
| Firewall | 10.0.0.16/28 | 16 | 5 (.16, .17, .18, .19 y .31) | 11 | 10.0.0.20 a 10.0.0.30 |
| Servidores | 10.0.0.32/28 | 16 | 5 (.32, .33, .34, .35 y .47) | 11 | 10.0.0.36 a 10.0.0.46 |

Se comprobó en la práctica: en fw-vpn, la tabla de rutas (ip route) muestra la ruta por defecto vía 10.0.0.17, que es la dirección del router que Azure reserva en la subred Firewall. La VNet 10.0.0.0/16 usa 16 bits de host, es decir, 65,536 direcciones.

## 4. Por qué los departamentos entran por VPN

Arquitectos, Ingenieros y TI no son subredes de Azure. Los empleados usan sus propias laptops y entran por un túnel OpenVPN a fw-vpn. Al conectarse, el servidor VPN les asigna una IP dentro del rango de su departamento, y el firewall (nftables) y los NSG deciden qué pueden alcanzar según esa IP de origen. Así los permisos viajan con la persona, ya sea que trabaje desde la oficina, la casa o la obra, y no hace falta crear máquinas en la nube para cada empleado. En esta fase solo se calculan y documentan los rangos; la asignación por OpenVPN se implementa en la siguiente fase.

## 5. Recursos desplegados

| VM | Subred | IP privada | IP pública | Tamaño | Sistema | Función |
|---|---|---|---|---|---|---|
| fw-vpn | Firewall | 10.0.0.20 (estática) | fw-vpn-ip (Standard) | Standard_B2ats_v2 | Ubuntu 24.04.4 LTS | Firewall, NAT, VPN, DNS y NTP (diseño) |
| srv-planos | Servidores | 10.0.0.36 (estática) | Ninguna | Standard_B2ats_v2 | Ubuntu 22.04.5 LTS | Samba y OpenLDAP (diseño) |
| srv-render | Servidores | 10.0.0.37 (estática) | Ninguna | Standard_B2ats_v2 | Ubuntu 22.04.5 LTS | Blender con CPU (diseño) |
| web | DMZ | 10.0.0.4 (diseño) | Diseño | n/a | n/a | No desplegada por la cuota de vCPU |

Todas las VMs usan autenticación por llave SSH (usuario azureuser). El software instalado es el base de Ubuntu (chrony activo; nftables, iptables y bind9-utils sin configurar). OpenVPN, BIND9, OpenLDAP, Samba, Nginx y Blender todavía no están instalados. El tamaño B1s del diseño original no está disponible en la suscripción de estudiante; los tamaños que sí aparecen en North Central US son de la serie Bsv2 (B2ats_v2, B2als_v2, B2as_v2, B4als_v2 y B4as_v2), todos de 2 o más vCPU. Se eligió B2ats_v2 por ser la más barata, a 0.0094 USD por hora según el portal.

## 6. Enrutamiento y seguridad

### Reenvío de IP en fw-vpn

Para que fw-vpn actúe como firewall y VPN debe reenviar tráfico entre redes. Esto requiere IP forwarding en la tarjeta de red desde Azure y net.ipv4.ip_forward=1 en Ubuntu. En Azure, la NIC fw-vpn434 ya tiene IP forwarding activo. En Ubuntu el valor era 0 durante las pruebas (figura 3) y después se activó en 1 de forma persistente (archivo evidencia/05-fw-vpn-ipforward.txt). [Agregar captura de la NIC con IP forwarding habilitado]

### Tablas de rutas (UDR), según el diagrama de la Fase 1

El diseño define dos tablas, una por subred, y deja la subred Firewall sin tabla para que fw-vpn no se mande tráfico a sí mismo. La IP de fw-vpn (10.0.0.20) debe ser estática.

| Tabla | Destino | Siguiente salto | Para qué |
|---|---|---|---|
| UDR Servidores | 0.0.0.0/0 | 10.0.0.20 (Virtual appliance) | Salida a Internet con NAT |
| UDR Servidores | 10.10.0.0/23 | 10.0.0.20 | Respuestas a usuarios VPN |
| UDR Servidores | 10.0.0.0/28 | 10.0.0.20 | Tráfico hacia la DMZ pasa por el firewall |
| UDR DMZ | 10.0.0.32/28 | 10.0.0.20 | Tráfico hacia Servidores pasa por el firewall |
| UDR DMZ | 10.10.0.0/23 | 10.0.0.20 | Tráfico hacia usuarios VPN |
| UDR DMZ | sin 0.0.0.0/0 | n/a | La web responde por su propia IP pública |
| Subred Firewall | sin UDR | n/a | Evita el bucle |

Estado al revisar el grupo de recursos (15 de octubre): las tablas todavía no están creadas, así que el tráfico entre subredes usa las rutas por defecto de Azure.

### Grupos de seguridad (NSG) y ACL

| NSG | Subred | Reglas de entrada aplicadas |
|---|---|---|
| nsg-dmz | DMZ | TCP 80 y 443 desde Internet; SSH 22 e ICMP desde 10.0.0.0/16 y 10.10.0.0/16; resto denegado |
| nsg-firewall | Firewall | UDP 1194 (OpenVPN) desde Internet; DNS 53 y NTP 123 e ICMP desde la VNet y la VPN; retorno de 10.0.0.0/16 hacia 10.10.0.0/16; SSH 22 solo desde la IP del administrador; resto denegado |
| nsg-servidores | Servidores | SSH 22 e ICMP desde la VNet y la VPN; SMB 445 desde los pooles de Arquitectos, Ingenieros y TI; LDAP 389 y 636 desde Firewall y Servidores; resto denegado (prioridad 4000) |

Los tres NSG están asociados a su subred y terminan con una regla Deny-Resto, como pide la política por defecto DROP del diagrama. Las reglas finas por departamento (por ejemplo, TI con acceso total y nadie iniciando hacia TI) se terminan con nftables en fw-vpn en la siguiente fase. En esta fase los pings entre VMs funcionan porque las reglas de ICMP y SSH permiten el tráfico de la propia VNet. Se usaron rangos de IP en vez de ASG, que eran opcionales. Para las pruebas se abrió SSH de forma temporal en nsg-dmz y nsg-servidores; esas reglas ya se eliminaron y el SSH a fw-vpn quedó limitado a la IP del administrador (evidencia/07-cambios-azure.txt).

## 7. Pruebas de conectividad

Las pruebas se hicieron el 15 de octubre de 2026 desde una laptop con Windows. Se entró por SSH a fw-vpn, que tiene IP pública, y desde ahí se saltó a las VMs de la subred Servidores por sus IP privadas (ssh -A -J), con reenvío del agente SSH para poder hacer SSH de srv-planos a srv-render sin copiar llaves a las VMs. Las horas de las capturas están en UTC.

- **Prueba 1, acceso a fw-vpn y verificación de su IP:** eth0 con 10.0.0.20/28 (figura 2).
- **Prueba 2, ping de fw-vpn hacia los servidores (entre subredes):** 4 de 4 hacia 10.0.0.36 (rtt promedio 0.620 ms) y hacia 10.0.0.37 (0.609 ms), 0% de pérdida. ip route muestra la ruta por defecto vía 10.0.0.17 y sysctl muestra net.ipv4.ip_forward = 0 (figura 3).
- **Prueba 3, SSH a srv-planos a través de fw-vpn:** la sesión inició en srv-planos con IP 10.0.0.36; el último inicio de sesión indica el origen 10.0.0.20 (figura 4).
- **Prueba 4, ping y SSH entre dos instancias de la misma subred** (prueba principal de la Fase 2): desde srv-planos, ping a srv-render 4 de 4, 0% de pérdida, rtt promedio 0.478 ms; el SSH a 10.0.0.37 abrió una sesión en srv-render (figuras 5 y 6).
- **Prueba 5, ping en sentido inverso:** desde srv-render hacia 10.0.0.36, 4 de 4, 0% de pérdida, rtt promedio 0.666 ms (figura 7).

| Prueba | Origen | Destino | Protocolo | Resultado |
|---|---|---|---|---|
| 1 | Laptop | fw-vpn (IP pública) | SSH 22 | Correcto; IP privada 10.0.0.20/28 |
| 2 | fw-vpn | 10.0.0.36 y 10.0.0.37 | ICMP | 4/4 y 4/4, 0% de pérdida |
| 3 | Laptop vía fw-vpn | srv-planos 10.0.0.36 | SSH 22 | Correcto |
| 4a | srv-planos | srv-render 10.0.0.37 | ICMP | 4/4, 0% de pérdida, 0.478 ms |
| 4b | srv-planos | srv-render 10.0.0.37 | SSH 22 | Correcto; sesión en srv-render |
| 5 | srv-render | srv-planos 10.0.0.36 | ICMP | 4/4, 0% de pérdida, 0.666 ms |

## 8. Problemas encontrados y cómo se resolvieron

| Problema | Causa | Solución |
|---|---|---|
| RequestDisallowedByPolicy al crear la red en Sweden Central | La suscripción solo permite 5 regiones | Se usó North Central US |
| B1s aparece como Size not available | La serie B de primera generación está restringida en Azure for Students | Se usó Standard_B2ats_v2 (2 vCPU) |
| Cuota de vCPU regional baja | Cada B2ats_v2 usa 2 vCPU; con 4 vCPU caben 2 VMs | Se priorizaron las VMs de la prueba principal; web y otras quedan diseñadas |
| Microsoft.Storage is not registered | El proveedor no estaba registrado y el rol sobre el grupo de recursos no permite registrarlo | Se desactivó boot diagnostics o el dueño de la suscripción registró el proveedor [confirmar cuál] |
| Run command no disponible | Limitación de permisos o de ubicación de la suscripción | Se autorizó la llave SSH desde una sesión existente |
| La primera fw-vpn quedó en una red nueva (172.16.0.0) | El asistente creó una VNet por defecto en vez de usar vnet-proyecto | Se eliminó y se recreó en la subred Firewall de vnet-proyecto |
| Subredes creadas como /24 | No coincidían con el VLSM de la Fase 1 | Se cambiaron a /28 antes de crear las VMs |

## 9. Costos

Cada B2ats_v2 cuesta 0.0094 USD por hora de uso. Los discos y las IP públicas se cobran aunque las VMs estén apagadas, por lo que es importante eliminar la IP pública temporal y detener las VMs (Stop con desasignación) al terminar. Las VMs se encienden solo para las pruebas y la demostración.

[Insertar captura: Cost Management, Cost analysis, con el gasto real acumulado y el crédito restante (responsable: Joel)]

[Escribir el costo real acumulado y comparar contra los $20.10 mensuales estimados en la Fase 1.]

## 10. Pendiente para la siguiente fase

Crear las dos tablas de rutas (UDR) y asociarlas a Servidores y DMZ; NAT con nftables; OpenVPN con IP por departamento; OpenLDAP, BIND9, Samba y Blender; web con Nginx y HTTPS en la DMZ; ACL fina con nftables; Azure DNS y Blob Storage; presupuesto y alertas en Cost Management.

## 11. Archivos de configuración y documentación

Se entregan: la exportación (Export template) del grupo de recursos; las salidas de las pruebas (01 a 05), la auditoría de Azure antes y después de los cambios (auditoria-azure.md, auditoria-raw.txt y auditoria-raw-2.txt) y el registro de cambios de seguridad (07); el inventario de software de las VMs (06); las capturas de este informe; y la guía de ejecución.

## Referencias

- Universidad del Valle de Guatemala (2026). Proyecto Final, Fase 1: Diseño de una red, Caso 4. Grupo de Redes, Sección 30.
- Universidad del Valle de Guatemala (2026). Proyecto Final, Fase 2: Implementación de una red, Sección 30.
- Microsoft (2026). Azure Virtual Network: direcciones IP reservadas en las subredes, tablas de rutas definidas por el usuario y reenvío de IP. Documentación de Azure.
