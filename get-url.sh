#!/bin/bash

echo "🔍 Getting service URL..."

# Get the node IP
NODE_IP=$(microk8s kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "📍 Node IP: $NODE_IP"
echo "🌐 Your app is accessible at: http://$NODE_IP:30008"
echo "📱 Test with: curl http://$NODE_IP:30008"

# Also show LoadBalancer IP if available
LB_IP=$(microk8s kubectl get service kz-node-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ ! -z "$LB_IP" ]; then
    echo "⚡ LoadBalancer IP: http://$LB_IP"
fi 