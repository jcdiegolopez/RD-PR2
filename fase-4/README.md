# Fase 4 · Red y servicios públicos

Entrega: 13 de noviembre. Enunciado: `enunciado-fase4.pdf`.

- **Plan final:** [`plan-fase4.md`](plan-fase4.md). Incluye el estado de partida, qué hay que cumplir (enunciado, caso 4 y pedidos del profesor), el orden de trabajo, el reparto, el calendario, las configuraciones, las pruebas, los costos y los riesgos.
- **Diagrama:** [`diagrama-fase4.drawio`](diagrama-fase4.drawio). Se abre con la extensión Draw.io Integration de VS Code o en app.diagrams.net.
- **Decisiones:**
  - La web pública entra por fw-vpn con DNAT y srv-web no tiene IP pública. Es un cambio respecto de la Fase 1; el plan B, darle IP propia, está en el plan.
  - La suscripción del proyecto pasa a pago por uso, para subir la cuota y crear `srv-web` en la DMZ.
  - Se mantienen srv-planos y srv-render, porque el caso 4 pide las dos máquinas y que Ingenieros solo entre a planos.
  - Se agrega la zona interna de DNS (BIND9), que pide el caso 4 y no se había hecho.
  - Samba y Blob Storage quedan fuera: no los pide ni la fase ni el caso.
