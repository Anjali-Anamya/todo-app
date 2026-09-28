#!/usr/bin/env bash

set -euo pipefail

IMAGE="${1:-todo-app:0.1.0}"

echo "======================================"
echo "Trivy image scan"
echo "Image: ${IMAGE}"
echo "======================================"

trivy image \
    --severity HIGH,CRITICAL \
    --ignore-unfixed \
    "${IMAGE}"

echo
echo "======================================"
echo "Filesystem security scan"
echo "======================================"

trivy fs \
    --scanners vuln,secret,misconfig \
    .
