#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-muchtodo-cluster}"
IMAGE_NAME="${IMAGE_NAME:-muchtodo-backend}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "==> Creating Kind cluster: ${CLUSTER_NAME}"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster already exists, skipping."
else
  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
      - containerPort: 80
        hostPort: 80
        protocol: TCP
EOF
fi

echo "==> Loading image into Kind..."
kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${CLUSTER_NAME}"

echo "==> Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "==> Applying manifests..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

echo "==> Waiting for deployments..."
kubectl rollout status deployment/mongodb-deployment -n muchtodo --timeout=120s
kubectl rollout status deployment/backend-deployment -n muchtodo --timeout=120s

echo ""
echo "✅ Deployment complete!"
kubectl get pods -n muchtodo
kubectl get svc -n muchtodo
kubectl get ingress -n muchtodo