#!/bin/bash

echo "🔄 Renewing SSL certificate for srv642680.hstgr.cloud"

# Renew certificate
sudo certbot renew --quiet

if [ $? -eq 0 ]; then
    echo "✅ Certificate renewed successfully!"
    
    # Copy updated certificates
    sudo cp /etc/letsencrypt/live/srv642680.hstgr.cloud/fullchain.pem /tmp/tls.crt
    sudo cp /etc/letsencrypt/live/srv642680.hstgr.cloud/privkey.pem /tmp/tls.key
    sudo chmod 644 /tmp/tls.crt
    sudo chmod 644 /tmp/tls.key
    
    # Update Kubernetes secret
    microk8s kubectl delete secret kz-backend-tls-real
    microk8s kubectl create secret tls kz-backend-tls-real \
        --cert=/tmp/tls.crt \
        --key=/tmp/tls.key
    
    # Restart SSL proxy to load new certificates
    microk8s kubectl rollout restart deployment ssl-proxy
    
    echo "🎉 SSL proxy updated with renewed certificate!"
    
    # Clean up
    rm -f /tmp/tls.crt /tmp/tls.key
else
    echo "⚠️ Certificate renewal not needed or failed"
fi