#!/bin/bash
# srv-planos: monitoreo SNMP → snmp_exporter → Prometheus → Grafana (solo TI).
# Uso: sudo bash setup-monitoreo.sh /tmp/monitoreo.txt
# monitoreo.txt: 3 líneas → clave SNMP auth, clave SNMP priv, clave del admin de Grafana
# Necesita en /tmp: grafana-dashboard.json
set -euo pipefail
CLAVES="${1:?Falta el archivo de claves}"
AUTH=$(sed -n 1p "$CLAVES" | tr -d '\r'); PRIV=$(sed -n 2p "$CLAVES" | tr -d '\r'); GPASS=$(sed -n 3p "$CLAVES" | tr -d '\r')
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq curl jq gpg >/dev/null

# ---------------- snmp_exporter (binario oficial de GitHub, verificado con sha256) ----------------
echo "===== snmp_exporter"
TAG=$(curl -fsSL https://api.github.com/repos/prometheus/snmp_exporter/releases/latest | jq -r .tag_name)
VER=${TAG#v}
URL=https://github.com/prometheus/snmp_exporter/releases/download/$TAG
TMP=$(mktemp -d); cd "$TMP"
curl -fsSLO "$URL/snmp_exporter-$VER.linux-amd64.tar.gz"
curl -fsSLO "$URL/sha256sums.txt"
grep " snmp_exporter-$VER.linux-amd64.tar.gz" sha256sums.txt | sha256sum -c -
tar xzf "snmp_exporter-$VER.linux-amd64.tar.gz"
install -m 755 "snmp_exporter-$VER.linux-amd64/snmp_exporter" /usr/local/bin/snmp_exporter
mkdir -p /etc/snmp_exporter
cp "snmp_exporter-$VER.linux-amd64/snmp.yml" /etc/snmp_exporter/snmp.yml
# Credencial SNMPv3 de Terranova (se agrega como primera entrada de "auths:")
awk -v a="$AUTH" -v p="$PRIV" '
  /^auths:/ && !hecho { print; print "  terranova_v3:\n    version: 3\n    username: monitor\n    security_level: authPriv\n    auth_protocol: SHA\n    password: " a "\n    priv_protocol: AES\n    priv_password: " p; hecho=1; next }
  { print }' /etc/snmp_exporter/snmp.yml > /etc/snmp_exporter/snmp.yml.nuevo
mv /etc/snmp_exporter/snmp.yml.nuevo /etc/snmp_exporter/snmp.yml
chmod 640 /etc/snmp_exporter/snmp.yml
id snmp_exporter >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin snmp_exporter
chgrp snmp_exporter /etc/snmp_exporter/snmp.yml
cat > /etc/systemd/system/snmp_exporter.service <<'EOF'
[Unit]
Description=Prometheus SNMP exporter
After=network-online.target

[Service]
User=snmp_exporter
ExecStart=/usr/local/bin/snmp_exporter --config.file=/etc/snmp_exporter/snmp.yml --web.listen-address=127.0.0.1:9116
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now snmp_exporter >/dev/null 2>&1
systemctl restart snmp_exporter
cd /; rm -rf "$TMP"
echo "snmp_exporter $VER activo"

# Módulos disponibles que nos interesan
MODULOS=""
for m in system if_mib hrStorage ucd_memory ucd_la_table; do
  grep -q "^  $m:" /etc/snmp_exporter/snmp.yml && MODULOS="$MODULOS${MODULOS:+, }$m"
done
echo "módulos: $MODULOS"

# ---------------- Prometheus (solo en localhost, 7 días) ----------------
echo "===== Prometheus"
apt-get install -y -qq --no-install-recommends prometheus >/dev/null
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 30s
  scrape_timeout: 20s

scrape_configs:
  - job_name: snmp
    metrics_path: /snmp
    params:
      auth: [terranova_v3]
      module: [$MODULOS]
    static_configs:
      - targets: ['10.0.0.20']
        labels: { equipo: fw-vpn }
      - targets: ['10.0.0.4']
        labels: { equipo: srv-web }
      - targets: ['10.0.0.36']
        labels: { equipo: srv-planos }
      - targets: ['10.0.0.37']
        labels: { equipo: srv-render }
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9116
  - job_name: snmp_exporter
    static_configs:
      - targets: ['127.0.0.1:9116']
EOF
echo 'ARGS="--web.listen-address=127.0.0.1:9090 --storage.tsdb.retention.time=7d"' > /etc/default/prometheus
systemctl restart prometheus
systemctl enable prometheus >/dev/null 2>&1
echo "prometheus $(prometheus --version 2>&1 | head -1 | awk '{print $3}') activo"

# ---------------- Grafana (repositorio oficial) ----------------
echo "===== Grafana"
mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -qq >/dev/null
apt-get install -y -qq grafana >/dev/null

cat > /etc/grafana/grafana.ini <<EOF
[server]
http_addr = 10.0.0.36
http_port = 3000
domain = grafana.terranova.local

[security]
admin_user = admin
admin_password = $GPASS
cookie_secure = false

[users]
allow_sign_up = false

[auth.anonymous]
enabled = false

[analytics]
reporting_enabled = false
check_for_updates = false
check_for_plugin_updates = false
EOF
chown root:grafana /etc/grafana/grafana.ini; chmod 640 /etc/grafana/grafana.ini

mkdir -p /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /var/lib/grafana/dashboards
cat > /etc/grafana/provisioning/datasources/prometheus.yaml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus-terranova
    type: prometheus
    access: proxy
    url: http://127.0.0.1:9090
    isDefault: true
EOF
cat > /etc/grafana/provisioning/dashboards/terranova.yaml <<'EOF'
apiVersion: 1
providers:
  - name: Terranova
    folder: Terranova
    type: file
    options:
      path: /var/lib/grafana/dashboards
EOF
cp /tmp/grafana-dashboard.json /var/lib/grafana/dashboards/red-terranova.json
chown -R grafana:grafana /var/lib/grafana/dashboards
systemctl daemon-reload
systemctl enable grafana-server >/dev/null 2>&1
systemctl restart grafana-server

shred -u "$CLAVES"

# ---------------- Verificación ----------------
sleep 20
echo "===== Verificación"
echo "--- escuchando"
ss -tlnp | grep -E ':(9116|9090|3000) ' | awk '{print $4, $6}'
echo "--- snmp_exporter → fw-vpn (sysName)"
curl -s "http://127.0.0.1:9116/snmp?target=10.0.0.20&auth=terranova_v3&module=system" | grep -E '^sysName' || echo "sin sysName"
echo "--- objetivos en Prometheus"
curl -s http://127.0.0.1:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job) \(.labels.instance) \(.health) \(.lastError)"'
echo "--- Grafana"
curl -s http://10.0.0.36:3000/api/health | jq -c .
