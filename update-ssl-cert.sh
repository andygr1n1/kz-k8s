#!/bin/bash

echo "Monitoring Let's Encrypt certificate for srv642680.hstgr.cloud..."
echo "Email: andy.grini@gmail.com"
echo ""

while true; do
    # Check if the Let's Encrypt certificate is ready
    CERT_READY=$(microk8s kubectl get certificate kz-backend-tls -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    
    if [ "$CERT_READY" = "True" ]; then
        echo "✅ Let's Encrypt certificate is ready! Updating SSL proxy..."
        
        # Update the SSL proxy to use the real certificate
        microk8s kubectl patch deployment ssl-proxy -p '{"spec":{"template":{"spec":{"volumes":[{"name":"ssl-certs","secret":{"secretName":"kz-backend-tls"}}]}}}}'
        
        echo "🔄 Restarting SSL proxy to use Let's Encrypt certificate..."
        microk8s kubectl rollout restart deployment ssl-proxy
        
        echo "🎉 SSL proxy now using Let's Encrypt certificate with your email!"
        echo "Certificate issued by Let's Encrypt for andy.grini@gmail.com"
        break
    else
        echo "⏳ Certificate still pending... (checking every 30s)"
        microk8s kubectl get certificate kz-backend-tls
    fi
    
    sleep 30
done

echo ""
echo "✅ Setup complete! Your backend is now secured with Let's Encrypt:"
echo "   https://srv642680.hstgr.cloud:30400"
echo "   Certificate email: andy.grini@gmail.com"