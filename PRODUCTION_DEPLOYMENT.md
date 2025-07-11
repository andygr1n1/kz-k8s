# Production Deployment Guide

## 🚀 Quick Start

1. **Deploy to production:**
   ```bash
   ./deploy-production.sh
   ```

2. **Access your app:**
   - URL: `https://srv642680.hstgr.cloud:448`
   - Test: `curl -k https://srv642680.hstgr.cloud:448`

## 📁 Files Overview

### Core Files
- `deployment.yaml` - Your application deployment
- `service-production.yaml` - Production service (ClusterIP)
- `ingress-production.yaml` - Basic Ingress with port 448
- `ingress-production-ssl.yaml` - SSL-enabled Ingress

### Scripts
- `deploy-production.sh` - Deploy everything to production
- `setup-ssl.sh` - SSL certificate setup guide

## 🔧 Configuration Options

### Option 1: Basic Setup (Current)
- Uses self-signed certificates
- Access with `-k` flag: `curl -k https://srv642680.hstgr.cloud:448`

### Option 2: Custom SSL Certificates
```bash
# Create secret with your certificates
kubectl create secret tls kz-node-tls \
  --cert=your-cert.pem \
  --key=your-key.pem

# Apply SSL-enabled ingress
kubectl apply -f ingress-production-ssl.yaml
```

### Option 3: Let's Encrypt (Automatic)
```bash
# Enable cert-manager
microk8s enable cert-manager

# Edit ingress-production-ssl.yaml to add cert-manager annotations
```

## 🌐 Network Configuration

### Ingress Controller
- **Port**: 448 (custom)
- **Protocol**: HTTPS
- **Domain**: srv642680.hstgr.cloud

### Service Configuration
- **Type**: ClusterIP (internal only)
- **Port**: 80 → 8008 (container)
- **Access**: Through Ingress only

## 🔍 Troubleshooting

### Check Status
```bash
# Check pods
kubectl get pods

# Check services
kubectl get services

# Check ingress
kubectl get ingress

# Check ingress logs
kubectl logs -n ingress nginx-ingress-microk8s-controller-*
```

### Common Issues
1. **SSL Certificate Errors**: Use `-k` flag for testing
2. **Port Not Accessible**: Check firewall rules for port 448
3. **Domain Not Resolving**: Ensure DNS points to your server

## 📊 Monitoring

### Health Check
```bash
curl -k https://srv642680.hstgr.cloud:448
# Expected: "Kzen drive"
```

### Logs
```bash
# Application logs
kubectl logs -l app=kz-node

# Ingress logs
kubectl logs -n ingress nginx-ingress-microk8s-controller-*
```

## 🔄 Updates

### Rolling Update
```bash
# Update deployment
kubectl apply -f deployment.yaml

# Or scale down/up
kubectl scale deployment kz-node --replicas=0
kubectl scale deployment kz-node --replicas=4
```

### Blue-Green Deployment
1. Deploy new version with different labels
2. Update service selector
3. Switch traffic instantly 