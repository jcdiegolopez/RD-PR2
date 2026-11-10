# Demo Fase 3 · Terranova · Turno de Diego López

Guion y comandos para la demo en vivo. Duración: **unos 8 minutos**.

Todo se hace desde **tu laptop** con:
- **OpenVPN GUI** (el candado junto al reloj) para conectarte como cada grupo.
- **PowerShell** abierto en la carpeta `RD-PR2\fase-3`, con letra grande.
- El **portal de Azure** abierto en `rg-redes-proyecto`.

> **Regla de oro:** un solo perfil de VPN conectado a la vez. Al cambiar de grupo: **Desconectar**, conectar el otro y esperar **5 segundos** antes del primer comando.

---

## ¿Tengo que configurar algo?

En **tu laptop no**: ya está todo listo.

| Qué | Estado |
|---|---|
| OpenVPN GUI instalado | Listo |
| Perfiles `prueba-arquitectos`, `prueba-ingenieros`, `prueba-ti`, `prueba-visitantes` | Listos en `C:\Users\dijol\OpenVPN\config` (entran solos, sin escribir clave) |
| `demo-ssh-config` (SSH a las VMs por la VPN de TI) | Listo en `RD-PR2\fase-3` |
| Tu IP pública | **No importa**: la VPN funciona desde cualquier red y el SSH va por la VPN de TI |

**Solo hay que hacer esto:**
1. **Encender las VMs** 15 minutos antes (si no están encendidas):

```powershell
$az = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"; $S = "17bfaf33-8d04-4cd4-8549-276b18b372ec"
& $az vm start --ids $(& $az vm list -g rg-redes-proyecto --subscription $S --query "[].id" -o tsv) -o none
```

2. **Ensayo de 1 minuto:** conectar `prueba-ti`, esperar 5 segundos y correr:

```powershell
ssh -F demo-ssh-config fw "systemctl is-active openvpn-server@arq openvpn-server@ing openvpn-server@ti openvpn-server@vis nftables chrony"
```

   Deben salir **6 veces `active`**. Desconectar `prueba-ti`.

> **Si presentas desde otra laptop:** necesita OpenVPN, los 4 perfiles `prueba-…` con sus `cred-….txt`, las dos llaves SSH (`redes_key` y `llave_compa`) y `demo-ssh-config` con esas rutas. Más fácil: presenta desde la tuya.

---

## Guion

### 1. La red en Azure · 1 min

**Haz:** en el portal, muestra el grupo de recursos y luego `nsg-firewall` → Reglas de entrada y de salida, y `rt-servidores` → Rutas.

**Di:**
> "Este es nuestro grupo de recursos: fw-vpn, srv-planos y srv-render. Cada subred tiene su NSG. Por ejemplo, Allow-OpenVPN deja entrar los puertos UDP 1194 a 1197 de nuestras cuatro VPN, y Allow-VPN-Hacia-Red es una regla de salida que nos faltaba y que encontramos al probar. Y esta tabla de rutas, rt-servidores, manda las respuestas a la VPN y la salida a Internet por fw-vpn, que es nuestro firewall."

---

### 2. Arquitectos: VPN, LDAP, DHCP e intranet · 1.5 min

**Haz:** OpenVPN GUI → `prueba-arquitectos` → **Conectar**. Espera 5 segundos.

```powershell
ipconfig | findstr 10.10.1
```

Luego abre en el navegador **http://10.0.0.37**.

**Di:**
> "Me conecto como Ana, de Arquitectos. Al conectar, fw-vpn validó mi usuario y contraseña contra OpenLDAP en srv-planos y revisó que soy del grupo arquitectos. Después la VPN me dio una IP dinámica de mi rango: 10.10.1 punto algo. Ese es el DHCP de la VPN; las VMs reciben su IP del DHCP de Azure.
> Ahora abro 10.0.0.37 y carga la Intranet Terranova. Corre en srv-render, solo en su IP privada; no tiene IP pública, así que desde Internet no hay forma de llegar."

---

### 3. Ingenieros: la ACL · 1.5 min

**Haz:** Desconectar → `prueba-ingenieros` → Conectar. Espera 5 segundos.

```powershell
Invoke-WebRequest http://10.0.0.37 -TimeoutSec 5 -UseBasicParsing | Select-Object StatusCode
ssh -o ConnectTimeout=5 ivan.ing@10.0.0.37
ssh -o ConnectTimeout=5 ivan.ing@10.0.0.36
```

Resultados esperados:
- La intranet responde `200`.
- El SSH a srv-render da `Connection timed out` a los 5 segundos.
- El SSH a srv-planos pide contraseña. No hace falta entrar: **Ctrl + C**.

**Di:**
> "Ahora soy de Ingenieros. La intranet también abre. Pero si intento entrar por SSH a srv-render, no me deja: lo bloquea nftables en fw-vpn, porque Ingenieros solo puede usar la web de render. En cambio a srv-planos sí llego. Esa diferencia es la ACL funcionando."

---

### 4. Visitantes: solo Internet · 1 min

**Haz:** Desconectar → `prueba-visitantes` → Conectar. Espera 5 segundos.

```powershell
Invoke-RestMethod https://api.ipify.org
Invoke-WebRequest http://10.0.0.37 -TimeoutSec 5 -UseBasicParsing
```

Resultados esperados:
- El primero muestra **la IP pública de fw-vpn**.
- El segundo falla por tiempo de espera.

**Di:**
> "Como visitante tengo Internet, y mi IP pública es la de fw-vpn: eso es el NAT. Pero la intranet no carga: los visitantes no llegan a nada interno."

---

### 5. TI: llega a todo y nadie llega a TI · 2 min

**Haz:** Desconectar → `prueba-ti` → Conectar. Espera 5 segundos.

```powershell
ipconfig | findstr 10.10.1
```

Anota la IP (por ejemplo 10.10.1.50) y úsala abajo:

```powershell
ssh -F demo-ssh-config fw "sudo nft list ruleset | grep nadie-hacia-TI"
ssh -F demo-ssh-config planos "ping -c 3 -W 2 10.10.1.50"
ssh -F demo-ssh-config fw "sudo nft list ruleset | grep nadie-hacia-TI"
```

Resultados esperados:
- El ping da **100% packet loss**.
- El número `packets` de la regla es **mayor** en la última línea que en la primera.

**Di:**
> "Soy de TI. TI llega a todo: entro por SSH al firewall y a los servidores. Ahora, desde srv-planos, intento llegar a mi laptop de TI y no puedo: 100% de pérdida. Y el contador de la regla 'nadie-hacia-TI' subió: esa es exactamente la regla que lo bloqueó. TI puede iniciar conexiones a todo, pero nadie puede iniciarlas hacia TI."

**Si sobra tiempo (30 s):**

```powershell
ssh -F demo-ssh-config fw "sudo chronyc clients"
```

> "Y aquí se ve el NTP: srv-planos y srv-render toman la hora de fw-vpn."

---

### Cierre

> "Eso es lo que implementamos en esta fase: DHCP, NTP, LDAP, la intranet, el firewall con la ACL, el NAT y el hardening. ¿Tienen preguntas?"

**Haz:** Desconectar la VPN.

---

## Si algo falla en vivo

Máximo **dos intentos** y pasar a la evidencia guardada en `evidencia/`.

| Síntoma | Qué hacer |
|---|---|
| El candado no se pone verde | Revisar que las VMs estén *Running*. Clic derecho → Ver log |
| `Unknown error` en el primer `ssh` | Esperaste poco: repítelo |
| Conecta pero no llega a nada | Ver que solo haya un perfil conectado; desconectar y volver a conectar |
| SSH da timeout con `prueba-ti` | Reintentar una vez |

| Plan B | Archivo |
|---|---|
| Pruebas de los 4 grupos y "nadie hacia TI" | `evidencia/11-pruebas-vpn.txt` |
| Login de VPN por grupo (LDAP) | `evidencia/07-vpn-ldap-auth.txt` |
| SSH con usuarios de LDAP | `evidencia/08-sssd-ssh.txt` |
| NTP | `evidencia/05-ntp.txt` |
| DHCP | `evidencia/12-dhcp.txt` |
| Hardening (puertos y escaneo) | `evidencia/09-hardening.txt` |

## Preguntas rápidas

| Pregunta | Respuesta corta |
|---|---|
| ¿Dónde están los usuarios? | En OpenLDAP, en srv-planos. fw-vpn no guarda contraseñas, solo pregunta |
| ¿Para qué el certificado si hay contraseña? | El certificado prueba que es una laptop de la empresa y que fw-vpn es el real; la contraseña prueba quién es la persona |
| ¿Dónde está el DHCP? | Azure da la IP a las VMs (no permite otro servidor DHCP); OpenVPN da IPs dinámicas por grupo a las laptops |
| ¿Por qué 4 VPN? | Una por grupo: cada una tiene su rango y solo acepta a su grupo de LDAP |
| ¿Por qué la web no está en la DMZ? | La DMZ es para lo que sale a Internet y la intranet es interna; además no hay cuota para otra VM |
| ¿Qué falta? | Samba, Blender y la web pública: son de la fase final |

## Al terminar

```powershell
$az = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"; $S = "17bfaf33-8d04-4cd4-8549-276b18b372ec"
& $az vm deallocate --ids $(& $az vm list -g rg-redes-proyecto --subscription $S --query "[].id" -o tsv) -o none
```
