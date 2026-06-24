#!/usr/bin/env python3
"""Envoi des métriques de scan de sécurité vers Prometheus Pushgateway."""

import os
import sys
import urllib.request
import urllib.error

PUSHGATEWAY_URL = os.environ.get("PUSHGATEWAY_URL", "http://localhost:9091")
JOB_NAME = "devsecops_scan"


def push_metric(metric_name, value, labels=""):
    """Envoyer une métrique au Pushgateway."""
    data = f"# TYPE {metric_name} gauge\n{metric_name}{{{labels}}} {value}\n"
    url = f"{PUSHGATEWAY_URL}/metrics/job/{JOB_NAME}"
    req = urllib.request.Request(url, data=data.encode(), method="POST")
    req.add_header("Content-Type", "text/plain")
    try:
        with urllib.request.urlopen(req, timeout=10) as response:  # nosec B310 — URL construite depuis une variable d'environnement interne, pas de l'input utilisateur
            return response.status
    except urllib.error.URLError as exc:
        print(f"Erreur connexion Pushgateway: {exc}", file=sys.stderr)
        return None


def main():
    cve_critical = int(os.environ.get("CVE_CRITICAL", "0"))
    cve_high = int(os.environ.get("CVE_HIGH", "0"))
    cis_controls = int(os.environ.get("CIS_CONTROLS", "15"))
    pipeline_status = int(os.environ.get("PIPELINE_STATUS", "1"))

    metrics = [
        ("cis_controls_applied_total", cis_controls, 'image="ubuntu-cis",level="1"'),
        ("cve_critical_count", cve_critical, 'image="ubuntu-cis"'),
        ("cve_high_count", cve_high, 'image="ubuntu-cis"'),
        ("pipeline_quality_score", pipeline_status, 'pipeline="ci-devsecops"'),
    ]

    for name, value, labels in metrics:
        status = push_metric(name, value, labels)
        if status:
            print(f"[OK] {name}={value} → HTTP {status}")
        else:
            print(f"[SKIP] {name}={value} (Pushgateway non joignable)")


if __name__ == "__main__":
    main()
