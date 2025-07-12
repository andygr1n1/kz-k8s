# Production Deployment Guide - HTTPS Backend on Port 30400

## 🚀 Quick Start

Deploy your backend service with HTTPS on port 30400:

```bash
# 1. Enable required microk8s addons
microk8s enable cert-manager

# 2. Deploy application
kubectl apply -f deployment.yaml

# 3. Create backend services
kubectl apply -f backend-http-service.yaml
kubectl apply -f combined-service.yaml

# 4. Set up SSL certificates
kubectl apply -f cert-issuer.yaml
kubectl apply -f backend-certificate.yaml

# 5. Deploy SSL proxy
kubectl apply -f ssl-proxy.yaml

# 6. Configure ingress for ACME challenges
kubectl apply -f ingress-ssl.yaml
```

## 🌐 Access URLs

- **Backend HTTPS**: `https://srv642680.hstgr.cloud:30400` (for API)
- **Frontend HTTPS**: `https://srv642680.hstgr.cloud` (for web interface)
- **HTTP**: `http://srv642680.hstgr.cloud` (redirects to HTTPS)

## 📁 Configuration Files

### 1. Core Application
```yaml
# deployment.yaml - Your kz-node application (4 replicas)
# Exposes port 8008 internally
```

### 2. Backend Services
```yaml
# backend-http-service.yaml - ClusterIP service for internal communication
apiVersion: v1
kind: Service
metadata:
  name: kz-node-direct
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8008
  selector:
    app: kz-node
```

### 3. SSL Certificate Setup
```yaml
# cert-issuer.yaml - Let's Encrypt certificate issuers
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: andy.grini@gmail.com  # Replace with your email
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
```

### 4. Backend Certificate
```yaml
# backend-certificate.yaml - Certificate for backend SSL
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kz-backend-tls
spec:
  secretName: kz-backend-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - srv642680.hstgr.cloud  # Replace with your domain
```

### 5. SSL Proxy Configuration
```yaml
# ssl-proxy.yaml - Nginx SSL termination proxy
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ssl-proxy-config
data:
  nginx.conf: |
    events { worker_connections 1024; }
    http {
        upstream backend {
            server kz-node-direct.default.svc.cluster.local:80;
        }
        server {
            listen 30400 ssl;
            server_name srv642680.hstgr.cloud;  # Replace with your domain
            
            ssl_certificate /etc/ssl/certs/tls.crt;
            ssl_certificate_key /etc/ssl/certs/tls.key;
            ssl_protocols TLSv1.2 TLSv1.3;
            
            location / {
                proxy_pass http://backend;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
    }
```

### 6. Service Configuration
```yaml
# combined-service.yaml - NodePort services for external access
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
    nodePort: 30400  # Backend HTTPS port
  selector:
    app: ssl-proxy
```

### 7. Ingress for ACME Challenges
```yaml
# ingress-ssl.yaml - Main ingress for Let's Encrypt validation
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kz-node-ingress-ssl
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - srv642680.hstgr.cloud  # Replace with your domain
    secretName: kz-node-tls
  rules:
  - host: srv642680.hstgr.cloud  # Replace with your domain
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

## 🔧 Setup Steps

### Prerequisites
```bash
# Ensure microk8s is running
microk8s status

# Required addons
microk8s enable ingress
microk8s enable cert-manager
microk8s enable dns
```

### Step 1: Deploy Application
```bash
kubectl apply -f deployment.yaml
```

### Step 2: Create Services
```bash
# Backend internal service
kubectl apply -f backend-http-service.yaml

# External HTTPS service
kubectl apply -f combined-service.yaml
```

### Step 3: Configure SSL Certificates
```bash
# Create Let's Encrypt issuers (update email in cert-issuer.yaml)
kubectl apply -f cert-issuer.yaml

# Request certificate for your domain
kubectl apply -f backend-certificate.yaml
```

### Step 4: Deploy SSL Proxy
```bash
# Create temporary certificate while Let's Encrypt processes
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/backend-tls.key -out /tmp/backend-tls.crt \
  -subj "/CN=srv642680.hstgr.cloud"

kubectl create secret tls kz-backend-tls-temp \
  --key=/tmp/backend-tls.key --cert=/tmp/backend-tls.crt

# Deploy SSL proxy
kubectl apply -f ssl-proxy.yaml
```

### Step 5: Configure Ingress
```bash
# Main ingress for ACME challenge validation
kubectl apply -f ingress-ssl.yaml
```

## 🔍 Verification

### Check Deployment Status
```bash
# Check all pods are running
kubectl get pods

# Check services
kubectl get svc

# Check ingress
kubectl get ingress

# Check certificates
kubectl get certificate
```

### Test Connectivity
```bash
# Test HTTP (for ACME challenges)
curl http://srv642680.hstgr.cloud

# Test HTTPS backend (with self-signed cert initially)
curl -k https://srv642680.hstgr.cloud:30400

# Expected response: "Kzen drive"
```

## 🔐 Certificate Management

### Monitor Let's Encrypt Certificate
```bash
# Check certificate status
kubectl get certificate kz-backend-tls

# Describe certificate for details
kubectl describe certificate kz-backend-tls

# Check certificate orders
kubectl get orders
```

### Auto-Update Script
Create `update-ssl-cert.sh`:
```bash
#!/bin/bash
echo "Monitoring Let's Encrypt certificate..."

while true; do
    CERT_READY=$(kubectl get certificate kz-backend-tls -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    
    if [ "$CERT_READY" = "True" ]; then
        echo "✅ Let's Encrypt certificate ready! Updating SSL proxy..."
        kubectl patch deployment ssl-proxy -p '{"spec":{"template":{"spec":{"volumes":[{"name":"ssl-certs","secret":{"secretName":"kz-backend-tls"}}]}}}}'
        kubectl rollout restart deployment ssl-proxy
        echo "🎉 SSL proxy now using Let's Encrypt certificate!"
        break
    else
        echo "⏳ Certificate still pending..."
        kubectl get certificate kz-backend-tls
    fi
    sleep 30
done
```

## 🚨 Troubleshooting

### Common Issues

1. **Certificate Not Issuing**
   ```bash
   # Check ACME challenge accessibility
   curl http://srv642680.hstgr.cloud/.well-known/acme-challenge/test
   
   # Should return your app response, not 404
   ```

2. **SSL Proxy Not Starting**
   ```bash
   # Check SSL proxy logs
   kubectl logs -l app=ssl-proxy
   
   # Verify certificate secret exists
   kubectl get secret kz-backend-tls-temp
   ```

3. **Port 30400 Not Accessible**
   ```bash
   # Check service ports
   kubectl get svc kz-backend-https
   
   # Check firewall (if needed)
   sudo ufw allow 30400
   ```

4. **502/503 Errors**
   ```bash
   # Check backend service connectivity
   kubectl get endpoints kz-node-direct
   
   # Check pod status
   kubectl get pods -l app=kz-node
   ```

### Logs
```bash
# Application logs
kubectl logs -l app=kz-node

# SSL proxy logs
kubectl logs -l app=ssl-proxy

# Ingress controller logs
kubectl logs -n ingress nginx-ingress-microk8s-controller-*

# Certificate manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

## 🔄 Updates and Maintenance

### Application Updates
```bash
# Rolling update
kubectl apply -f deployment.yaml

# Force restart
kubectl rollout restart deployment kz-node
```

### Certificate Renewal
Let's Encrypt certificates auto-renew. Monitor with:
```bash
kubectl get certificate kz-backend-tls -o yaml
```

### Scaling
```bash
# Scale application
kubectl scale deployment kz-node --replicas=6

# Scale SSL proxy (if needed)
kubectl scale deployment ssl-proxy --replicas=2
```

## 📊 Architecture Overview

```
Internet → Port 30400 (HTTPS) → SSL Proxy → kz-node-direct → kz-node pods
         → Port 80/443 (HTTP/HTTPS) → Ingress → kz-node-direct → kz-node pods
```

- **Backend API**: Port 30400 (HTTPS only)
- **Frontend**: Port 80/443 (for future web interface)
- **SSL Termination**: Nginx SSL proxy
- **Certificates**: Let's Encrypt with auto-renewal
- **Load Balancing**: Kubernetes services + 4 replica pods

## 🌟 Production Checklist

- [ ] Update domain name in all config files
- [ ] Update email address in cert-issuer.yaml
- [ ] Verify DNS points to your server
- [ ] Test HTTPS access on port 30400
- [ ] Verify Let's Encrypt certificate issues
- [ ] Set up monitoring/alerting
- [ ] Configure backups if needed
- [ ] Document API endpoints for frontend team