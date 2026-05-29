#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-muchtodo-cluster}"

echo "==> Deleting all resources in namespace muchtodo..."
kubectl delete namespace muchtodo --ignore-not-found=true

echo ""
echo "==> Deleting Kind cluster: ${CLUSTER_NAME}..."
kind delete cluster --name "${CLUSTER_NAME}"

echo ""
echo "✅ Cleanup complete."