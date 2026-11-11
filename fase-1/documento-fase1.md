# Proyecto Final CC3067 · Fase 1 · Diseño de una Red

Universidad del Valle de Guatemala · Redes · Facultad de Ingeniería · Sección 30 · Juan Carlos Canteo Boix

Proyecto final, Fase 1

Jose Pablo (23773) · Joel Jaquez (23369) · Diego López (23242) · Erick Guerra (23208) · Diego Rosales (23258) · Fabian Morales (23267)

Guatemala, 21 de agosto 2026

## Resumen del caso

La propuesta es montar la red de la empresa en Microsoft Azure con tres subredes en la nube (DMZ, Firewall y Servidores) y tres subredes de usuarios (Arquitectos, Ingenieros y TI) que el firewall entrega por la VPN. La empresa es una desarrolladora de bienes raíces con dos edificios de apartamentos y un condominio de casas en desarrollo.

El grupo usará Azure for Students, que da $100 de crédito por 12 meses sin tarjeta. El documento cubre la lista de tecnologías, la estimación de costos, los casos de uso de negocio con el marco regulatorio de Guatemala y una guía para dibujar el diagrama. El nombre de la empresa y el dominio público quedan pendientes de definir.

## Lista de tecnologías

La red usa 25 tecnologías, casi todas de Azure o de código abierto. El firewall, la VPN y los servicios internos corren en máquinas virtuales propias.

| Grupo | Tecnología | Qué es | Uso en esta red |
|---|---|---|---|
| Red base | Azure Virtual Network (VNet) | Red privada y aislada dentro de Azure | Contiene las subredes de la empresa en el bloque 10.0.0.0/16 |
| Red base | Subredes | Partes del rango de la VNet | Separan DMZ, Firewall y Servidores dentro de Azure |
| Red base | Tablas de rutas (UDR) | Rutas definidas por el usuario que cambian el camino por defecto | Mandan a fw-vpn el tráfico entre subredes y el de los usuarios de la VPN (10.10.0.0/16) |
| Red base | IP pública estática | Dirección pública fija en Azure | Una para fw-vpn y otra para el servidor web |
| Seguridad | Firewall en VM Linux con nftables | Máquina Ubuntu con reenvío de IP activo que filtra y enruta tráfico | Firewall central de la red, con las reglas de la ACL |
| Seguridad | Network Security Groups (NSG) | Reglas de permitir o bloquear por subred o por tarjeta de red | Segunda capa de la ACL, por ejemplo la subred Servidores solo acepta a Ingenieros en el puerto de planos |
| Seguridad | Application Security Groups (ASG) | Etiquetas que agrupan máquinas dentro de las reglas NSG | Reglas por rol, como "planos" o "render", en vez de IP sueltas |
| Seguridad | NAT | Traduce IP privadas a una IP pública | Lo hace fw-vpn, los usuarios y servidores salen a Internet sin quedar expuestos |
| Seguridad | OpenVPN | VPN moderna y ligera que crea un túnel cifrado | Todos los empleados entran por aquí, desde la oficina o desde casa, y cada uno recibe una IP fija en la subred de su departamento |
| Seguridad | SSH con llaves | Acceso remoto cifrado a servidores Linux | Cada grupo entra a los servidores de su rol: arquitectos a srv-render y srv-planos, ingenieros a srv-planos y TI a todos. Cada servidor solo acepta a los grupos de LDAP permitidos |
| Seguridad | Hardening | Cerrar puertos y servicios que no se usan | Cada máquina deja abiertos solo los puertos de su servicio |
| Servicios internos | DHCP de Azure | Azure asigna la IP privada de cada máquina según su subred | Reparte las IP de los servidores y les entrega como DNS a fw-vpn. A los usuarios de la VPN la IP se la asigna fw-vpn |
| Servicios internos | BIND9 | Servidor DNS | Corre en fw-vpn con la zona interna para encontrar planos y render por nombre |
| Servicios internos | chrony (NTP) | Servicio que sincroniza la hora | Corre en fw-vpn, toma la hora del host de Azure y la reparte a todos los equipos |
| Servicios internos | OpenLDAP | Directorio de usuarios y grupos | Corre en srv-planos, con un usuario por persona y los grupos arquitectos, ingenieros y ti |
| Servidores | Azure Virtual Machines | Máquinas virtuales | Cuatro máquinas B1s, fw-vpn, web, srv-planos y srv-render |
| Servidores | Discos administrados Standard SSD | Discos de las máquinas virtuales | Un disco de 32 GB por máquina, donde también quedan los planos y renders |
| Servidores | Azure Blob Storage | Almacenamiento de archivos por objetos | Respaldos de planos y renders |
| Servidores | Samba | Carpetas compartidas en red | Carpeta de planos en srv-planos con permisos por grupo de LDAP |
| Servidores | Blender Cycles | Motor de renderización | Corre en srv-render con CPU y guarda los resultados en srv-planos |
| Servicios públicos | Nginx | Servidor web | Página pública con los proyectos en desarrollo, dentro de la DMZ |
| Servicios públicos | Dominio .me | Nombre público de la empresa | Gratis por 1 año con el GitHub Student Developer Pack |
| Servicios públicos | Azure DNS | DNS público administrado | Zona pública del dominio con registros hacia la web y la VPN |
| Servicios públicos | Let's Encrypt con Certbot | Certificados SSL gratis y renovables | HTTPS para la página web |
| Monitoreo | Cost Management y presupuestos | Alertas de gasto | Aviso por correo antes de acabarse el crédito |

El firewall se propone sobre Ubuntu y no con OPNsense del Marketplace, porque el crédito de Azure for Students no cubre productos del Marketplace ([términos de la oferta](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0170p)).

## Estimación de tecnologías de nube y costos

El proyecto cuesta unos $20 al mes en Azure. Si las máquinas se apagan cuando no se usan, entonces el crédito de $100 alcanza para unos 5 meses. Se despliegan 4 máquinas pequeñas, que es lo que permite la cuenta de estudiante.

### Límites de Azure for Students

- Da $100 de crédito por 12 meses sin tarjeta, y si se acaba los servicios se detienen sin cobrar ([detalle de la oferta](https://creditforstartups.com/students/azure-for-students)).
- Solo deja crear recursos en algunas regiones, por ejemplo Sweden Central o Germany West Central, y la lista cambia entre cuentas ([regiones permitidas](https://learn.microsoft.com/en-us/answers/questions/5931331/azure-for-students-allowed-5-regions-not-possible)).
- Otros estudiantes reportan una cuota de unos 4 vCPU que no se puede aumentar y ninguna máquina con GPU ([cuotas y políticas](https://techcommunity.microsoft.com/discussions/microsoft-learn-for-educators/sku-quota-and-policy-restrictions-on-azure-for-students-and-free-subscriptions/4525160)).
- El crédito no cubre productos del Marketplace ([términos de la oferta](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0170p)).

Por eso el diseño usa 4 máquinas de 1 vCPU, el render corre con CPU y los empleados entran con sus propias laptops por la VPN, en vez de tener máquinas en la nube.

### Recursos y costo mensual

Supuestos: región Sweden Central, precios Linux en USD y 60 horas al mes de uso (unas 15 por semana de trabajo del grupo), con las máquinas apagadas el resto del tiempo.

| Recurso | Tamaño o SKU | Uso al mes | Costo al mes (USD) |
|---|---|---|---|
| fw-vpn (firewall, NAT, VPN, DNS y NTP) | B1s, 1 vCPU y 1 GB | 60 h | 0.65 |
| web (Nginx en la DMZ) | B1s, 1 vCPU y 1 GB | 60 h | 0.65 |
| srv-planos (Samba y OpenLDAP) | B1s, 1 vCPU y 1 GB | 60 h | 0.65 |
| srv-render (Blender con CPU) | B1s, 1 vCPU y 1 GB | 60 h | 0.65 |
| Discos de sistema | 4 discos Standard SSD E4 de 32 GB | mes completo | 9.60 |
| IP públicas | 2 estáticas Standard, para fw-vpn y web | 730 h | 7.30 |
| DNS público | Azure DNS, 1 zona | mes completo | 0.50 |
| Respaldos | Blob Storage Hot LRS, 5 GB | mes completo | 0.10 |
| Salida a Internet | Menos de 100 GB, que son gratis | mes completo | 0.00 |
| Dominio | .me gratis por 1 año con el GitHub Student Developer Pack ([Namecheap](https://aistudentdiscount.com/blog/free-domain-names-for-students/)) | 1 año | 0.00 |
| **Total** | | | **20.10** |

Los discos y las IP públicas son el 84% del gasto, porque cobran aunque las máquinas estén apagadas. Si las 4 máquinas quedan encendidas todo el mes el costo sube a unos $49 y el crédito dura solo 2 meses. Entonces hay que detenerlas desde el portal al terminar cada sesión y crear un presupuesto con alerta en Cost Management.

### Servicios administrados que no se usan

Azure tiene VPN y NAT administrados, pero cobran por hora aunque nadie los use. El VPN Gateway VpnGw1 cuesta $0.19 por hora, o sea unos $139 al mes, más que todo el crédito. Por eso el firewall, el NAT y la VPN van juntos en fw-vpn, que también permite configurar las reglas a mano en las siguientes fases.

## Casos de uso de negocio

La infraestructura resuelve seis necesidades concretas del negocio, cada una amarrada a una parte de la red.

| # | Caso de uso | Quién lo usa | Cómo lo resuelve la red | Valor para el negocio |
|---|---|---|---|---|
| 1 | Diseñar y renderizar los proyectos | Arquitectos (15) | Entran al servidor de planos y mandan trabajos al servidor de render, que solo se enciende cuando hace falta | Renders de los edificios y del condominio sin comprar estaciones con GPU para cada persona |
| 2 | Revisar planos para la obra | Ingenieros (10) | Leen los planos del servidor compartido, pero la ACL les bloquea el render | Todos trabajan sobre la misma versión del plano y se evitan errores en obra por archivos viejos |
| 3 | Trabajar desde casa o desde la obra | Arquitectos, Ingenieros y TI | VPN con usuario de LDAP, cada departamento recibe IP de su rango y conserva sus permisos | El equipo sigue trabajando fuera de la oficina sin exponer los servidores a Internet |
| 4 | Mostrar los proyectos a compradores | Clientes y público | Página web con HTTPS en la DMZ, separada de la red interna | Canal de ventas abierto 24 horas, y si la web es atacada el atacante no llega a los planos |
| 5 | Administrar y dar soporte | TI (3) | TI llega a todas las subredes, nadie puede iniciar conexión hacia TI, y administra con SSH por llave | Control central de usuarios, parches y respaldos, con las cuentas de administración protegidas |
| 6 | Proteger la información de la empresa | Toda la empresa | Respaldos en Blob Storage, logs de tráfico y un solo directorio de usuarios que se da de baja en un paso | Los planos son el activo principal, perderlos o filtrarlos retrasa la obra y afecta la confianza de los compradores |

Otro beneficio es la escala. Si entra más personal se crea su usuario en LDAP y se le da una IP libre en la subred de su departamento, y si hacen falta más renders se cambia el tamaño de srv-render, sin comprar equipo físico.

## Regulación y cumplimiento para bienes raíces

La regla que más pesa sobre la red es la de prevención de lavado de dinero. En Guatemala las inmobiliarias son personas obligadas ante la IVE, y eso las obliga a guardar los registros de clientes y transacciones al menos 5 años. Guatemala todavía no tiene una ley general de protección de datos personales, entonces se toman marcos internacionales como guía.

| Norma o marco | Qué pide | Cómo lo cubre la red |
|---|---|---|
| [Decreto 67-2001](https://banguat.gob.gt/sites/default/files/banguat/leyes/2021/ley_contra_lavado_de_dinero.pdf), Ley contra el Lavado de Dinero u Otros Activos | Registrar a los clientes en formularios de la IVE (art. 21), conservar los registros mínimo 5 años después de la transacción (art. 23) y reportar de inmediato las transacciones sospechosas (art. 26) | Expedientes de clientes en el servidor de planos con carpeta aparte, acceso solo por grupo de LDAP y respaldos en Blob Storage con retención de 5 años |
| [Acuerdo Gubernativo 443-2013](https://www.gpi.com.gt/ive-personas-obligadas-por-que-las-inmobiliarias-son-personas-obligadas-y-la-responsabilidad-de-los-compradores/) y Decreto 58-2005 | Incluyen a quienes se dedican a actividades inmobiliarias como personas obligadas, con oficial de cumplimiento, capacitación y auditoría. Las multas van de US$10,000 a US$50,000 | Logs de acceso y de tráfico que sirven como evidencia en una auditoría, y cuentas personales para saber quién abrió cada archivo |
| [Régimen de propiedad horizontal](https://www.amberlegal.com.gt/post/la-propiedad-horizontal-en-guatemala-la-nueva-realidad-de-la-vida-en-los-edificios), Código Civil (Decreto Ley 106) | Para inscribir cada apartamento se presentan escritura, autorización municipal y planos de la finca matriz, de cada unidad y de las áreas comunes | Los planos viven en un solo servidor con permisos y respaldos, así la versión que se inscribe es la correcta y no se pierde |
| [Protección de datos por jurisprudencia](https://consortiumlegal.com/en/2026/09/23/data-protection-habeas-data-guatemala/) | No hay ley específica. La Corte de Constitucionalidad reconoce la autodeterminación informativa y se protege por amparo | Los datos de compradores (DPI, ingresos, contactos) quedan en subredes privadas, cifrados en disco, y nunca en la DMZ |
| [Ley de Protección al Consumidor y Usuario](https://www.congreso.gob.gt/assets/uploads/info_legislativo/decretos/06-03.pdf), Decreto 06-2003 | Regula la relación entre proveedores y consumidores, lo que incluye la información que se ofrece al vender | La página web solo publica información aprobada de los proyectos y TI controla quién puede cambiarla |
| Decreto 47-2008, Ley para el Reconocimiento de las Comunicaciones y Firmas Electrónicas | Da validez legal a documentos y firmas electrónicas | Si se firman contratos o reservas en línea, HTTPS y el registro de accesos respaldan que el documento no fue alterado |
| ISO/IEC 27001 y NIST CSF 2.0 | Marcos internacionales para gestionar la seguridad de la información | Sirven como guía por la falta de ley de datos. La red ya aplica varios controles, como segmentación, mínimo privilegio, cifrado, respaldos y monitoreo |
