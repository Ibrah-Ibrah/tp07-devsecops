#!/usr/bin/env bash
# Envoi des métriques de scan DevSecOps vers Prometheus Pushgateway
set -euo pipefail

PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"
JOB="devsecops_scan"

CVE_CRITICAL="${CVE_CRITICAL:-0}"
CVE_HIGH="${CVE_HIGH:-0}"
CIS_CONTROLS="${CIS_CONTROLS:-15}"
PIPELINE_STATUS="${PIPELINE_STATUS:-1}"

push() {
  local metric="$1" value="$2" labels="$3"
  printf "# TYPE %s gauge\n%s{%s} %s\n" \
    "$metric" "$metric" "$labels" "$value" \
    | curl -sf --data-binary @- "${PUSHGATEWAY_URL}/metrics/job/${JOB}" \
    && echo "[OK] ${metric}=${value}"
}

echo "=== Push métriques DevSecOps → ${PUSHGATEWAY_URL} ==="

push "cis_controls_applied_total" "$CIS_CONTROLS"  'image="ubuntu-cis",level="1"'
push "cve_critical_count"         "$CVE_CRITICAL"  'image="ubuntu-cis"'
push "cve_high_count"             "$CVE_HIGH"       'image="ubuntu-cis"'
push "pipeline_quality_score"     "$PIPELINE_STATUS" 'pipeline="ci-devsecops"'

echo "=== Métriques envoyées avec succès ==="
