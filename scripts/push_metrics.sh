#!/usr/bin/env bash
# Envoi des métriques de scan DevSecOps vers Prometheus Pushgateway
set -euo pipefail

PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"
JOB="devsecops_scan"

# Si un fichier rapport Trivy est passé en argument, on parse les vrais résultats
if [[ "${1:-}" != "" && -f "$1" ]]; then
  REPORT="$1"
  CVE_CRITICAL=$(grep -oE 'CRITICAL: [0-9]+' "$REPORT" | grep -oE '[0-9]+' | awk '{s+=$1} END {print s+0}')
  CVE_HIGH=$(grep -oE 'HIGH: [0-9]+' "$REPORT" | grep -oE '[0-9]+' | awk '{s+=$1} END {print s+0}')
  PIPELINE_STATUS=$(( CVE_CRITICAL == 0 && CVE_HIGH == 0 ? 1 : 0 ))
  echo "[INFO] Rapport Trivy parsé : CRITICAL=${CVE_CRITICAL} HIGH=${CVE_HIGH}"
else
  CVE_CRITICAL="${CVE_CRITICAL:-0}"
  CVE_HIGH="${CVE_HIGH:-0}"
  PIPELINE_STATUS="${PIPELINE_STATUS:-1}"
fi

CIS_CONTROLS="${CIS_CONTROLS:-15}"

push() {
  local metric="$1" value="$2" labels="$3"
  printf "# TYPE %s gauge\n%s{%s} %s\n" \
    "$metric" "$metric" "$labels" "$value" \
    | curl -sf --data-binary @- "${PUSHGATEWAY_URL}/metrics/job/${JOB}" \
    && echo "[OK] ${metric}=${value}"
}

echo "=== Push métriques DevSecOps → ${PUSHGATEWAY_URL} ==="

push "cis_controls_applied_total" "$CIS_CONTROLS"    'image="ubuntu-cis",level="1"'
push "cve_critical_count"         "$CVE_CRITICAL"    'image="ubuntu-cis"'
push "cve_high_count"             "$CVE_HIGH"         'image="ubuntu-cis"'
push "pipeline_quality_score"     "$PIPELINE_STATUS"  'pipeline="ci-devsecops"'

echo "=== Métriques envoyées avec succès ==="
