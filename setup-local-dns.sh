#!/bin/bash

echo "🔧 Setting up local DNS entry..."

# Get the node IP
NODE_IP=$(microk8s kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Add to /etc/hosts if not already there
if ! grep -q "kz-node.local" /etc/hosts; then
    echo "📝 Adding kz-node.local to /etc/hosts..."
    echo "$NODE_IP kz-node.local" | sudo tee -a /etc/hosts
    echo "✅ Added: $NODE_IP kz-node.local"
else
    echo "✅ kz-node.local already exists in /etc/hosts"
fi

echo "🌐 Your app is now accessible at: http://kz-node.local:30008"
echo "📱 Test with: curl http://kz-node.local:30008" 