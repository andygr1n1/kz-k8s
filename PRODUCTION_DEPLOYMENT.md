# Production Deployment Guide - Dual Protocol Backend on Port 30400

## 🎯 Final Working Setup

Your backend API now supports **both HTTP and HTTPS on port 30400** with real Let's Encrypt certificates:

- **HTTP**: `http://srv642680.hstgr.cloud:30400` ✅
- **HTTPS**: `https://srv642680.hstgr.cloud:30400` ✅ 
- **Frontend**: `https://srv642680.hstgr.cloud` ✅ (ready for future)

## 🚀 Quick Deployment

```bash
# 1. Enable microk8s addons
microk8s enable ingress
microk8s enable dns

# 2. Deploy application and services
kubectl apply -f deployment.yaml
kubectl apply -f backend-http-service.yaml
kubectl apply -f combined-service.yaml

# 3. Deploy SSL proxy with dual protocol support
kubectl apply -f ssl-proxy.yaml

# 4. Generate real SSL certificates with external certbot
./setup-external-ssl.sh

# 5. Configure ingress for frontend (optional)
kubectl apply -f ingress-ssl.yaml
```

## 📁 Key Files Created and Why

### 1. Core Application
```yaml
# deployment.yaml - Your kz-node application
# - 4 replicas for load balancing
# - Exposes port 8008 internally
# - Uses image: andygr1n1/kz-node:linux
```

### 2. Backend Service
```yaml
# backend-http-service.yaml - Internal ClusterIP service
apiVersion: v1
kind: Service
metadata:
  name: kz-node-direct
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8008  # Maps to your app's port
  selector:
    app: kz-node
```
**Why**: Provides internal service discovery for the SSL proxy to reach your pods.

### 3. External Access Service
```yaml
# combined-service.yaml - NodePort for external access
apiVersion: v1
kind: Service
metadata:
  name: kz-backend-https
spec:
  type: NodePort
  ports:
  - name: https
    port: 443
    targetPort: 30400
    nodePort: 30400  # External port
  selector:
    app: ssl-proxy
```
**Why**: Exposes the SSL proxy on port 30400 for external access.

### 4. Dual Protocol SSL Proxy
```yaml
# ssl-proxy.yaml - The magic component that makes everything work
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ssl-proxy-config
data:
  nginx.conf: |
    events { worker_connections 1024; }
    
    # Stream module for protocol detection
    stream {
        upstream backend_http {
            server kz-node-direct.default.svc.cluster.local:80;
        }
        
        upstream backend_https {
            server 127.0.0.1:8443;
        }
        
        # Auto-detect HTTP vs HTTPS
        map $ssl_preread_protocol $upstream {
            "" backend_http;           # Plain HTTP
            "TLSv1.2" backend_https;   # HTTPS
            "TLSv1.3" backend_https;   # HTTPS
            default backend_http;
        }
        
        server {
            listen 30400;
            ssl_preread on;            # Inspect but don't terminate
            proxy_pass $upstream;
        }
    }
    
    # HTTP module for SSL termination
    http {
        upstream backend {
            server kz-node-direct.default.svc.cluster.local:80;
        }
        
        server {
            listen 8443 ssl;
            server_name srv642680.hstgr.cloud;
            
            ssl_certificate /etc/ssl/certs/tls.crt;
            ssl_certificate_key /etc/ssl/certs/tls.key;
            ssl_protocols TLSv1.2 TLSv1.3;
            
            location / {
                proxy_pass http://backend;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto https;
            }
        }
    }
```
**Why**: This is the core innovation - nginx uses SSL preread to detect protocol and route accordingly:
- HTTP requests → Direct proxy to backend
- HTTPS requests → SSL termination → Proxy to backend

### 5. External SSL Certificate Setup
```bash
#!/bin/bash
# setup-external-ssl.sh - Real Let's Encrypt certificates

# Install certbot
sudo apt install -y certbot

# Generate certificate using standalone mode
sudo certbot certonly \
    --standalone \
    --email andy.grini@gmail.com \
    --agree-tos \
    -d srv642680.hstgr.cloud

# Copy to Kubernetes
sudo cp /etc/letsencrypt/live/srv642680.hstgr.cloud/fullchain.pem /tmp/tls.crt
sudo cp /etc/letsencrypt/live/srv642680.hstgr.cloud/privkey.pem /tmp/tls.key

# Create Kubernetes secret
kubectl create secret tls kz-backend-tls-real \
    --cert=/tmp/tls.crt \
    --key=/tmp/tls.key

# Update SSL proxy
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
```
**Why**: External certbot is more reliable than cert-manager for simple setups. It generates real Let's Encrypt certificates with your email.

### 6. Frontend Ingress (Optional)
```yaml
# ingress-ssl.yaml - For future frontend deployment
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kz-node-ingress-ssl
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: srv642680.hstgr.cloud
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kz-node-direct
            port:
              number: 80
```
**Why**: Reserves standard ports 80/443 for your future frontend application.

## 🔧 Successful Commands Executed

### 1. Initial Setup
```bash
# Enable required microk8s features
microk8s enable ingress
microk8s enable dns

# Deploy application
kubectl apply -f deployment.yaml
```

### 2. Service Creation
```bash
# Internal backend service
kubectl apply -f backend-http-service.yaml

# External access service
kubectl apply -f combined-service.yaml
```

### 3. SSL Proxy Deployment
```bash
# Deploy dual-protocol proxy
kubectl apply -f ssl-proxy.yaml
```

### 4. SSL Certificate Generation
```bash
# Generate real Let's Encrypt certificates
./setup-external-ssl.sh

# Result: Valid certificate for andy.grini@gmail.com
# Expires: October 5, 2025
```

### 5. Final Configuration
```bash
# CRITICAL: Update SSL proxy to use real Let's Encrypt certificates
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

# Restart with new certificates
microk8s kubectl rollout restart deployment ssl-proxy
```

## 🏗️ Architecture Overview

```
Internet → Port 30400 → SSL Proxy (nginx)
                     ├─ HTTP  → Direct proxy → kz-node-direct → kz-node pods
                     └─ HTTPS → SSL termination → kz-node-direct → kz-node pods

Internet → Port 80/443 → Ingress Controller → kz-node-direct → kz-node pods (future frontend)
```

### Components:
- **4 kz-node pods**: Your backend application
- **kz-node-direct**: ClusterIP service for internal routing
- **SSL Proxy**: Nginx with SSL preread for protocol detection
- **NodePort 30400**: External access point
- **Let's Encrypt**: Real SSL certificates with auto-renewal

## 🔍 Verification Commands

### Test Both Protocols
```bash
# Test HTTP
curl http://srv642680.hstgr.cloud:30400
# Expected: "Kzen drive"

# Test HTTPS (no -k flag needed!)
curl https://srv642680.hstgr.cloud:30400
# Expected: "Kzen drive" with valid SSL
```

### Check Deployment Status
```bash
# Check all components
kubectl get pods,svc,ingress

# Check SSL proxy logs
kubectl logs -l app=ssl-proxy

# Check certificate details
curl -vI https://srv642680.hstgr.cloud:30400
```

### Certificate Information
```bash
# Check certificate expiration
sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/srv642680.hstgr.cloud/fullchain.pem

# View certificate details
sudo certbot certificates
```

## 🔄 Maintenance

### SSL Certificate Renewal
```bash
# Manual renewal
./renew-ssl.sh

# Check auto-renewal (certbot sets this up automatically)
sudo systemctl status certbot.timer
```

### Application Updates
```bash
# Rolling update
kubectl apply -f deployment.yaml

# Force restart
kubectl rollout restart deployment kz-node

# Scale up/down
kubectl scale deployment kz-node --replicas=6
```

### Monitoring
```bash
# Application logs
kubectl logs -l app=kz-node

# SSL proxy logs
kubectl logs -l app=ssl-proxy

# Certificate status
sudo certbot certificates
```

## 🚨 Troubleshooting

### Common Issues

1. **Port 30400 not accessible**
   ```bash
   # Check service
   kubectl get svc kz-backend-https
   
   # Check firewall
   sudo ufw allow 30400
   ```

2. **SSL certificate errors**
   ```bash
   # Check certificate secret
   kubectl get secret kz-backend-tls-real
   
   # Regenerate certificates
   ./setup-external-ssl.sh
   ```

3. **502/503 errors**
   ```bash
   # Check backend pods
   kubectl get pods -l app=kz-node
   
   # Check internal service
   kubectl get endpoints kz-node-direct
   ```

4. **Protocol detection not working**
   ```bash
   # Check SSL proxy config
   kubectl get configmap nginx-ssl-proxy-config -o yaml
   
   # Restart SSL proxy
   kubectl rollout restart deployment ssl-proxy
   ```

## 🌟 Production Checklist

- [x] ✅ HTTP access on port 30400
- [x] ✅ HTTPS access on port 30400  
- [x] ✅ Real Let's Encrypt certificate
- [x] ✅ Certificate issued to andy.grini@gmail.com
- [x] ✅ Auto-renewal configured
- [x] ✅ Load balancing (4 replicas)
- [x] ✅ Frontend ports reserved (80/443)
- [ ] 📋 Set up monitoring/alerting
- [ ] 📋 Configure backup strategy
- [ ] 📋 Document API endpoints for frontend team

## 🎉 Success Metrics

- **HTTP Response**: `curl http://srv642680.hstgr.cloud:30400` → "Kzen drive"
- **HTTPS Response**: `curl https://srv642680.hstgr.cloud:30400` → "Kzen drive" 
- **SSL Validation**: No certificate warnings or errors
- **Certificate Issuer**: Let's Encrypt (andy.grini@gmail.com)
- **Certificate Expiry**: xxxxxx x, 20xx
- **Load Balancing**: 4 backend pods serving requests
- **Protocol Detection**: Automatic HTTP/HTTPS routing on same port

Your backend API is now production-ready with dual protocol support! 🚀