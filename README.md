# KZen Node Kubernetes Deployment

This repository contains Kubernetes configurations for deploying the KZen Node application in both development and production environments.

## 🚀 Quick Start

### Development (Local)
```bash
# Deploy to development
./deploy.sh

# Access your app
curl http://kz-node.local:30008
```

### Production (KVM Server)
```bash
# Deploy to production
./deploy-production.sh

# Access your app
curl -k https://srv642680.hstgr.cloud:448
```

## 📁 Project Structure

```
k8s/
├── deployment.yaml              # Application deployment
├── service.yaml                # Development service (NodePort)
├── service-production.yaml     # Production service (ClusterIP)
├── ingress-production.yaml     # Production Ingress
├── ingress-production-ssl.yaml # SSL-enabled Ingress
├── nginx.yaml                  # Optional nginx service
├── metallb-config.yaml         # MetalLB configuration
├── deploy.sh                   # Development deployment script
├── deploy-production.sh        # Production deployment script
├── get-url.sh                  # Get current service URL
├── setup-local-dns.sh          # Local DNS setup
├── setup-ssl.sh               # SSL certificate setup
├── DEVELOPMENT_DEPLOYMENT.md   # Development guide
├── PRODUCTION_DEPLOYMENT.md    # Production guide
├── ENVIRONMENT_COMPARISON.md   # Environment comparison
└── README.md                   # This file
```

## 🌍 Environment Overview

| Environment | URL | Service Type | SSL | Port |
|-------------|-----|--------------|-----|-------|
| **Development** | `http://kz-node.local:30008` | NodePort | No | 30008 |
| **Production** | `https://srv642680.hstgr.cloud:448` | ClusterIP + Ingress | Yes | 448 |

## 🔧 Prerequisites

### Development
- microk8s installed and running
- Local network access

### Production
- microk8s installed on KVM server
- Domain name pointing to server
- SSL certificates (optional)

## 📚 Documentation

- **[Development Guide](DEVELOPMENT_DEPLOYMENT.md)** - Complete development setup and workflow
- **[Production Guide](PRODUCTION_DEPLOYMENT.md)** - Production deployment with SSL
- **[Environment Comparison](ENVIRONMENT_COMPARISON.md)** - Differences between dev and prod

## 🛠️ Common Commands

### Development
```bash
# Deploy
./deploy.sh

# Setup DNS
./setup-local-dns.sh

# Get URL
./get-url.sh

# Check status
microk8s kubectl get all
```

### Production
```bash
# Deploy
./deploy-production.sh

# Setup SSL
./setup-ssl.sh

# Check ingress
microk8s kubectl get ingress
```

## 🔍 Troubleshooting

### Development Issues
- **DNS not working**: Run `./setup-local-dns.sh`
- **Port not accessible**: Check `microk8s kubectl get services`
- **Pods not ready**: Check `microk8s kubectl get pods`

### Production Issues
- **SSL errors**: Use `-k` flag or run `./setup-ssl.sh`
- **Domain not resolving**: Check DNS configuration
- **Port 448 blocked**: Check firewall rules

## 🎯 Features

### Development Features
- ✅ Local DNS resolution (`kz-node.local`)
- ✅ Direct NodePort access
- ✅ Hot reload support
- ✅ Resource monitoring
- ✅ Easy debugging

### Production Features
- ✅ SSL/HTTPS support
- ✅ Custom domain access
- ✅ Ingress traffic management
- ✅ Load balancing
- ✅ SSL certificate management

## 🔄 Switching Environments

### Development → Production
```bash
microk8s kubectl delete -f service.yaml
./deploy-production.sh
```

### Production → Development
```bash
microk8s kubectl delete -f ingress-production.yaml
microk8s kubectl delete -f service-production.yaml
./deploy.sh
```

## 📊 Monitoring

### Health Checks
```bash
# Development
curl http://kz-node.local:30008

# Production
curl -k https://srv642680.hstgr.cloud:448
```

### Logs
```bash
# Application logs
microk8s kubectl logs -f -l app=kz-node

# Ingress logs (production)
microk8s kubectl logs -n ingress nginx-ingress-microk8s-controller-*
```

## 🤝 Contributing

1. Test changes in development first
2. Update relevant documentation
3. Test production deployment
4. Update version tags if needed

## 📝 License

This project is part of the KZen Node application. 