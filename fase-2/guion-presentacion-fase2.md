# Guion de la presentación · Fase 2 (Terranova)

Dura unos 13 minutos. Cada persona tiene su parte. El mismo texto está en las notas de cada diapositiva.

| Diapositivas | Quién | Tiempo |
|---|---|---|
| 1–2 · Portada y qué pide la Fase 2 | Jose Pablo | 1:30 |
| 3–4 · Cuenta de estudiante y la red | Joel | 2:00 |
| 5–6 · Cálculo de subredes y departamentos | Diego Rosales | 2:30 |
| 7–9 · Máquinas, seguridad y acceso | Erick | 2:45 |
| 10–11 · Pruebas y demo en vivo | Diego López | 3:30 |
| 12–14 · Qué falta, costos y cierre | Fabian | 2:15 |

---

## Jose Pablo (1:30)

**1 · Portada.** Buenos días. Somos Terranova, la empresa de bienes raíces del caso 4. En la Fase 1 diseñamos la red. Hoy les mostramos cómo la montamos en Azure y cómo la probamos. Al final hay una demo en vivo.

**2 · Qué pide la Fase 2.** La Fase 2 pide tres cosas. Uno, montar la red en una nube; usamos Azure. Dos, aplicar el cálculo de subredes de la Fase 1. Tres, probar que dos máquinas de la misma subred se pueden comunicar, con ping y con SSH. Las tres están hechas. Lo que falta, como la VPN, es de la Fase 3. Joel sigue.

## Joel (2:00)

**3 · Cambios por la cuenta de estudiante.** Usamos Azure for Students, y la cuenta tiene límites:
- Sweden Central no está permitida, así que usamos North Central US.
- El tamaño B1s no está disponible, así que usamos B2ats_v2, el más barato que sí sale.
- Cada VM usa 2 vCPU y hay un límite, así que hicimos 3 VMs. La web queda para la Fase 3.
- Dos servidores quedaron con Ubuntu 22.04, pero no afecta la red.

**4 · La red en Azure.** Creamos una red virtual, vnet-proyecto, con el rango 10.0.0.0/16. Adentro hay tres subredes: DMZ, Firewall y Servidores, cada una con sus reglas de seguridad. En Firewall está fw-vpn y en Servidores están srv-planos y srv-render. La DMZ está lista, pero la web va en la Fase 3. También creamos las subredes de los departamentos; eso lo explica Diego Rosales.

## Diego Rosales (2:30)

**5 · Cálculo de subredes.** El tamaño de cada subred depende de cuántas personas o máquinas tiene. Arquitectos son 15. Con 4 bits salen 14 IPs útiles y no alcanza; con 5 bits salen 30, entonces es un /27. Ingenieros son 10 y les alcanza un /28 con 14. TI son 3 y les alcanza un /29 con 6. En Azure cada subred pierde 5 IPs que usa Azure, por eso un /28 deja 11 y la primera IP libre es la .4. Así quedaron fw-vpn en la .20 y los servidores en la .36 y la .37.

**6 · Subredes de los departamentos.** Creamos en Azure las subredes de Arquitectos, Ingenieros y TI, pero son **temporales**: solo están para mostrar el cálculo en la nube y no tienen máquinas. En el diseño real, los empleados entran con su laptop por **OpenVPN**, y OpenVPN les da una IP de su departamento; por ejemplo, alguien de TI recibe la 10.10.1.50. Si dejáramos estas subredes y la VPN al mismo tiempo, habría un problema: cuando un servidor le responda a 10.10.1.50, Azure cree que esa IP está en la subred TI de Azure y manda la respuesta ahí, no a fw-vpn. Esa subred está vacía, así que la respuesta se pierde. Por eso las borramos antes de activar la VPN en la Fase 3. Erick sigue.

## Erick (2:45)

**7 · Las máquinas virtuales.** Tenemos tres máquinas. fw-vpn es el firewall, está en la .20 y es la única con IP pública. srv-planos y srv-render son los servidores, en la .36 y la .37, sin IP pública: nadie llega a ellos directo desde Internet. Las tres tienen IP fija.

**8 · Reglas de seguridad.** Cada subred tiene reglas de seguridad; en Azure se llaman NSG. Solo pasa lo permitido y lo demás se bloquea. El firewall acepta la VPN desde Internet y SSH solo desde la IP del administrador. La DMZ acepta la página web. Los servidores solo aceptan conexiones desde adentro. Para probar abrimos SSH a Internet por un rato; antes de entregar lo cerramos.

**9 · Cómo entramos a los servidores.** Como solo fw-vpn tiene IP pública, siempre entramos por ahí. Desde la laptop entramos a fw-vpn con una llave SSH, sin contraseña. De ahí saltamos a srv-planos, y de srv-planos a srv-render. En fw-vpn ya activamos el reenvío de paquetes, que le permite funcionar como router. Falta la VPN, las reglas del firewall, el NAT y las rutas, que son de la Fase 3. Diego López sigue.

## Diego López (3:30)

**10 · Pruebas de conectividad.** Hicimos seis pruebas y todas salieron bien. Las importantes son ping y SSH entre srv-planos y srv-render, que están en la misma subred. En el ping mandamos 4 paquetes y regresaron los 4, sin pérdida. Con SSH entramos de srv-planos a srv-render. También probamos el ping de regreso y desde el firewall. Ahora lo vemos en vivo.

**11 · Demo en vivo.** (Ver `demo-en-vivo.md`.)
1. Entro a fw-vpn y muestro su nombre y su IP.
2. Salto a srv-planos.
3. Hago ping a srv-render: "4 recibidos, 0% de pérdida".
4. Entro por SSH a srv-render: el nombre cambia a srv-render y la IP es 10.0.0.37.

Si falla, máximo dos intentos y muestro las salidas de la carpeta `evidencia/`. Le paso la palabra a Fabian.

## Fabian (2:15)

**12 · Qué hicimos y qué falta.** Comparado con el diagrama de la Fase 1, la red ya está completa: subredes, máquinas, reglas de seguridad y el firewall listo para enrutar. Faltan los servicios: la VPN, las reglas del firewall, las rutas, la web, el DNS, las carpetas compartidas y los renders. Eso es la Fase 3.

**13 · Cuánto cuesta.** Buscamos los precios oficiales de Azure. Cada VM cuesta menos de un centavo por hora, cada disco 2.40 al mes y la IP pública 3.65 al mes. Con las VMs encendidas 60 horas al mes, el total es unos 12.54 dólares, y el crédito de 100 alcanza para unos 8 meses. Los discos y la IP cobran aunque todo esté apagado; eso ya son 10.85 al mes. Por eso apagamos las máquinas cuando no las usamos.

**14 · Resumen.** Creamos las 6 subredes en Azure, las pruebas salieron sin pérdida y todo cuesta unos 12.54 dólares al mes. Gracias. ¿Preguntas?

---

## Precios usados (fuente: lista oficial de Azure, North Central US, Linux, consultada el 15 oct 2026)

| Recurso | Precio | Cálculo | Al mes |
|---|---|---|---|
| VM B2ats_v2 (×3) | $0.0094 por hora | 3 × 60 h × 0.0094 | $1.69 |
| Disco Standard SSD E4, 32 GB (×3) | $2.40 al mes | 3 × 2.40 | $7.20 |
| IP pública Standard fija (×1) | $0.005 por hora | 730 h × 0.005 | $3.65 |
| **Total (60 h al mes)** | | | **$12.54** |

- Todo apagado (solo discos e IP): $10.85 al mes.
- Todo encendido 24/7: 3 × 730 × 0.0094 = $20.59 en VMs, total $31.44 al mes.
- No incluye cosas pequeñas como operaciones de disco o tráfico de salida (los primeros 100 GB son gratis).
- Son precios de lista: lo que cobra de verdad se ve en Cost Management.

## Preguntas probables

| Pregunta | Quién | Respuesta corta |
|---|---|---|
| ¿Por qué /28 si hay 1 o 2 máquinas? | Diego Rosales | Azure guarda 5 IPs. Un /29 deja solo 3; un /28 deja 11 y hay espacio para crecer. |
| ¿Por qué las subredes de departamento no tienen máquinas? | Diego Rosales | Porque los empleados entran con su laptop por la VPN. La IP se la da la VPN. |
| ¿Por qué no usan la VPN de Azure? | Erick | Cuesta unos $139 al mes, más que todo el crédito. |
| ¿Cómo llegan a servidores sin IP pública? | Diego López | Entrando primero a fw-vpn y saltando desde ahí por SSH. |
| ¿Por qué North Central US? | Joel | Sweden Central no está permitida en la cuenta de estudiante. |
| ¿Por qué cuesta menos que en la Fase 1? | Fabian | Hay 3 discos en vez de 4 y una IP pública en vez de dos. |

## Antes de presentar

- [ ] Encender las 3 VMs 15 minutos antes.
- [ ] Revisar la IP de la laptop de la demo (`demo-en-vivo.md`, paso 1.2).
- [ ] Al terminar: Stop (deallocated) en las 3 VMs.
