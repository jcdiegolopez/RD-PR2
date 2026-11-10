# Guía de la demo en vivo · Fase 2

Quién: Diego López · Duración: unos 2:30 · Terminal: PowerShell en tu laptop.

> Este archivo tiene la IP pública de fw-vpn y tu IP. Es solo para ti: no lo subas al repo.

## Datos

| Qué | Valor |
|---|---|
| IP pública de fw-vpn | `52.162.223.107` |
| Tu IP permitida en `Allow-SSH-Admin` | `190.14.138.110` |
| fw-vpn (privada) | `10.0.0.20` |
| srv-planos | `10.0.0.36` |
| srv-render | `10.0.0.37` |
| Usuario en las 3 VMs | `azureuser` |
| Llave de fw-vpn | `C:\Windows\System32\redes_key` |
| Llave de srv-planos y srv-render | `C:\Users\dijol\.ssh\llave_compa` |

---

## 1. Antes de la presentación (15 minutos antes)

**1.1 Encender las VMs.** Portal → Virtual machines → seleccionar `fw-vpn`, `srv-planos` y `srv-render` → **Start**. Esperar a que digan *Running* (unos 2 minutos).

**1.2 Revisar tu IP pública.** El SSH a fw-vpn solo acepta tu IP.

```powershell
Invoke-RestMethod https://api.ipify.org
```

- Si sale `190.14.138.110`: todo bien.
- Si sale otra (otra red, la U, datos móviles): Portal → `nsg-firewall` → Inbound security rules → `Allow-SSH-Admin` → cambiar **Source IP addresses** a la IP nueva con `/32` → Save. Tarda menos de un minuto en aplicarse.

**1.3 Revisar que las llaves estén en el agente.**

```powershell
ssh-add -l
```

Deben salir 3 llaves (una termina en `DIEGO-LENOVO`, otra en `JP`). Si sale "Could not open a connection to your authentication agent" o falta alguna:

```powershell
Start-Service ssh-agent
ssh-add C:\Windows\System32\redes_key
ssh-add $HOME\.ssh\llave_compa
```

**1.4 Ensayo rápido** (no interactivo, solo para confirmar que todo responde):

```powershell
ssh -i C:\Windows\System32\redes_key -o IdentitiesOnly=yes -o ConnectTimeout=10 azureuser@52.162.223.107 "hostname"
```

Debe imprimir `fw-vpn`. Si responde, la demo va a funcionar.

**1.5 Preparar la pantalla.** Terminal con letra grande (Ctrl + rueda del mouse), fondo oscuro, sin otras ventanas encima. Ten abierta la carpeta `evidencia/` por si hace falta el plan B.

---

## 2. Durante la demo (lo que escribes y lo que dices)

### Paso 1 · Entrar a fw-vpn (≈30 s)

```powershell
ssh -i C:\Windows\System32\redes_key -o IdentitiesOnly=yes azureuser@52.162.223.107
```

Ya dentro de fw-vpn:

```bash
hostname
ip -4 -br addr show
sysctl net.ipv4.ip_forward
exit
```

**Qué señalar:** el nombre `fw-vpn`, la IP `10.0.0.20/28` y `net.ipv4.ip_forward = 1`.
**Qué decir:** "Entramos a la única máquina con IP pública. Está en la subred Firewall y ya tiene activado el reenvío de paquetes."

### Paso 2 · Saltar a srv-planos (≈20 s)

```powershell
ssh -A -i $HOME\.ssh\llave_compa -J azureuser@52.162.223.107 azureuser@10.0.0.36
```

```bash
hostname
ip -4 -br addr show
```

**Qué señalar:** `srv-planos` y `10.0.0.36/28`.
**Qué decir:** "srv-planos no tiene IP pública. Llegamos saltando por fw-vpn con `-J`, y `-A` nos deja usar la llave sin copiarla al servidor."

### Paso 3 · Ping entre los servidores (≈20 s) · prueba principal

```bash
ping -c 4 10.0.0.37
```

**Qué señalar:** la línea `4 packets transmitted, 4 received, 0% packet loss`.
**Qué decir:** "Esta es la prueba que pide el enunciado: dos instancias de la misma subred, Servidores. Llegan los 4 paquetes, sin pérdida y en menos de un milisegundo."

### Paso 4 · SSH de srv-planos a srv-render (≈30 s)

```bash
ssh azureuser@10.0.0.37
```

```bash
hostname
ip -4 -br addr show
ping -c 4 10.0.0.36
```

**Qué señalar:** el prompt cambia de `azureuser@srv-planos` a `azureuser@srv-render`, la IP `10.0.0.37/28` y el ping de regreso con `0% packet loss`.
**Qué decir:** "Ahora estamos en srv-render: el SSH entre las dos máquinas funciona y el ping en sentido contrario también, así que ninguna regla bloquea un lado."

### Paso 5 · Salir (≈5 s)

```bash
exit
exit
```

**Qué decir:** "Con esto cubrimos ping y SSH dentro de la subred y el acceso por el firewall. Le paso la palabra a Fabian."

---

## 3. Si algo falla

Máximo **dos intentos** por comando. Si no sale, pasa al plan B sin pelearte con la terminal en vivo.

| Síntoma | Causa probable | Qué hacer en el momento |
|---|---|---|
| Se queda colgado o `Connection timed out` al entrar a fw-vpn | Tu IP cambió, o las VMs están apagadas | Plan B. Después: revisar 1.1 y 1.2 |
| `Permission denied (publickey)` | Llave no cargada en el agente | `ssh-add -l`, cargar la que falte (1.3) y reintentar una vez |
| `Host key verification failed` | La VM se recreó | No borrar nada en vivo: plan B |
| El ping no responde | Regla NSG cambiada | Plan B |

**Plan B:** abre `evidencia/02-srv-planos.txt` (ping) y `evidencia/03-srv-render.txt` (SSH y ping de regreso) y explica las mismas líneas: `4 received, 0% packet loss` y el hostname `srv-render`. Usa las capturas del reporte si las tienen.

---

## 4. Al terminar la presentación

1. Portal → Virtual machines → seleccionar las 3 → **Stop**. Esperar a *Stopped (deallocated)*.
2. Si cambiaste `Allow-SSH-Admin` para la demo, déjalo con la IP que vayas a usar después.
