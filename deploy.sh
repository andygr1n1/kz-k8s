#!/bin/bash

echo "🚀 Deploying kz-node application..."

# Apply all configurations
microk8s kubectl apply -f deployment.yaml
microk8s kubectl apply -f service.yaml

echo "⏳ Waiting for pods to be ready..."
microk8s kubectl wait --for=condition=ready pod -l app=kz-node --timeout=60s

echo "📊 Checking service status..."
microk8s kubectl get services

echo "✅ Deployment complete!"
echo "🌐 Your app is accessible at: http://kz-node.local:30008"
echo "📱 Or use: curl http://kz-node.local:30008"
echo "🔧 If DNS doesn't work, use: http://192.168.64.2:30008" 