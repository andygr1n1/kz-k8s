#!/bin/bash

echo "🔐 Setting up SSL-enabled production deployment..."

# Enable cert-manager if not already enabled
if ! microk8s kubectl get namespace cert-manager >/dev/null 2>&1; then
    echo "📦 Enabling cert-manager for automatic SSL..."
    microk8s enable cert-manager
    echo "⏳ Waiting for cert-manager to be ready..."
    microk8s kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=120s
fi

echo "📋 Applying ClusterIssuer for Let's Encrypt..."
microk8s kubectl apply -f cluster-issuer.yaml

echo "🚀 Deploying application..."
microk8s kubectl apply -f deployment.yaml
microk8s kubectl apply -f service-production.yaml

echo "⏳ Waiting for pods to be ready..."
microk8s kubectl wait --for=condition=ready pod -l app=kz-node --timeout=60s

echo "🌐 Applying SSL-enabled ingress..."
microk8s kubectl apply -f ingress-production.yaml

echo "📊 Checking deployment status..."
microk8s kubectl get pods
microk8s kubectl get services
microk8s kubectl get ingress

echo "🔍 Checking certificate status..."
microk8s kubectl get certificates
microk8s kubectl get certificaterequests

echo "✅ SSL-enabled production deployment complete!"
echo "🌐 Your app will be accessible at: https://srv642680.hstgr.cloud:30448"
echo "📱 Test with: curl https://srv642680.hstgr.cloud:30448"

echo ""
echo "📋 Certificate Status:"
echo "Check certificate status: microk8s kubectl get certificates"
echo "Check certificate requests: microk8s kubectl get certificaterequests"
echo "Check certificate events: microk8s kubectl describe certificate kz-node-tls" 