#!/bin/bash

echo "🔐 Setting up SSL certificates for production..."

# Check if cert-manager is enabled
if ! microk8s kubectl get namespace cert-manager >/dev/null 2>&1; then
    echo "📦 Enabling cert-manager for automatic SSL..."
    microk8s enable cert-manager
fi

echo ""
echo "🔧 SSL Setup Options:"
echo "1. Use Let's Encrypt (automatic):"
echo "   - Edit ingress-production-ssl.yaml"
echo "   - Add cert-manager annotations"
echo ""
echo "2. Use your own certificates:"
echo "   - Create a Kubernetes secret with your certs:"
echo "   kubectl create secret tls kz-node-tls \\"
echo "     --cert=your-cert.pem \\"
echo "     --key=your-key.pem"
echo ""
echo "3. Use self-signed for testing:"
echo "   - The current config uses snakeoil certs"
echo "   - Access with: curl -k https://srv642680.hstgr.cloud:448"
echo ""
echo "🌐 Your app will be accessible at: https://srv642680.hstgr.cloud:448" 