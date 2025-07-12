#!/bin/bash

echo "🚀 Deploying kz-node to production..."

# Apply production configurations
microk8s kubectl apply -f deployment.yaml
microk8s kubectl apply -f service-production.yaml
microk8s kubectl apply -f ingress-production.yaml

echo "⏳ Waiting for pods to be ready..."
microk8s kubectl wait --for=condition=ready pod -l app=kz-node --timeout=60s

echo "📊 Checking service status..."
microk8s kubectl get services

echo "🌐 Checking ingress status..."
microk8s kubectl get ingress

echo "✅ Production deployment complete!"
echo "🌐 Your app will be accessible at: https://srv642680.hstgr.cloud:448"
echo "📱 Test with: curl -k https://srv642680.hstgr.cloud:448"

echo ""
echo "🔧 To configure SSL certificates:"
echo "1. Replace the SSL certificate paths in ingress-production.yaml"
echo "2. Or use cert-manager for automatic SSL: microk8s enable cert-manager" 
