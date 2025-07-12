#!/bin/bash

echo "🔐 Setting up SSL certificates with external certbot"
echo "Email: andy.grini@gmail.com"
echo "Domain: srv642680.hstgr.cloud"
echo ""

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    sudo apt update
    sudo apt install -y certbot
fi

# Stop any service that might be using port 80
echo "🛑 Temporarily stopping services on port 80..."
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true

# Generate certificate using standalone mode
echo "🔄 Generating Let's Encrypt certificate..."
sudo certbot certonly \
    --standalone \
    --email andy.grini@gmail.com \
    --agree-tos \
    --no-eff-email \
    -d srv642680.hstgr.cloud

if [ $? -eq 0 ]; then
    echo "✅ Certificate generated successfully!"
    
    # Copy certificates to accessible location
    echo "📋 Copying certificates..."
    sudo cp /etc/letsencrypt/live/srv642680.hstgr.cloud/fullchain.pem /tmp/tls.crt
    sudo cp /etc/letsencrypt/live/srv642680.hstgr.cloud/privkey.pem /tmp/tls.key
    sudo chmod 644 /tmp/tls.crt
    sudo chmod 644 /tmp/tls.key
    
    # Create Kubernetes secret with real certificates
    echo "🔧 Creating Kubernetes secret..."
    microk8s kubectl delete secret kz-backend-tls-temp 2>/dev/null || true
    microk8s kubectl create secret tls kz-backend-tls-real \
        --cert=/tmp/tls.crt \
        --key=/tmp/tls.key
    
    # Update SSL proxy to use real certificates
    echo "🔄 Updating SSL proxy..."
    microk8s kubectl patch deployment ssl-proxy -p '{
        "spec": {
            "template": {
                "spec": {
                    "volumes": [
                        {
                            "name": "ssl-certs",
                            "secret": {
                                "secretName": "kz-backend-tls-real"
                            }
                        }
                    ]
                }
            }
        }
    }'
    
    # Restart SSL proxy
    echo "🔄 Restarting SSL proxy..."
    microk8s kubectl rollout restart deployment ssl-proxy
    
    echo ""
    echo "🎉 SSL setup complete!"
    echo "✅ HTTPS: https://srv642680.hstgr.cloud:30400"
    echo "✅ HTTP:  http://srv642680.hstgr.cloud:30400"
    echo "📧 Certificate issued to: andy.grini@gmail.com"
    echo ""
    echo "📅 Certificate expires: $(sudo openssl x509 -enddate -noout -in /tmp/tls.crt | cut -d= -f2)"
    
else
    echo "❌ Certificate generation failed!"
    echo "💡 Make sure:"
    echo "   - DNS points to this server"
    echo "   - Port 80 is accessible from internet"
    echo "   - No firewall blocking port 80"
fi

# Clean up
rm -f /tmp/tls.crt /tmp/tls.key