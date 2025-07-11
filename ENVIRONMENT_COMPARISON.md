# Environment Comparison

## 🆚 Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| **Access URL** | `http://kz-node.local:30008` | `https://srv642680.hstgr.cloud:448` |
| **Service Type** | NodePort | ClusterIP + Ingress |
| **SSL** | No | Yes (HTTPS) |
| **Port** | 30008 | 448 |
| **DNS** | Local hostname | Domain name |
| **Deploy Script** | `./deploy.sh` | `./deploy-production.sh` |

## 📁 File Structure

### Development Files
```
├── deployment.yaml          # App deployment
├── service.yaml            # NodePort service
├── deploy.sh              # Development deploy script
├── get-url.sh             # Get current URL
├── setup-local-dns.sh     # Local DNS setup
└── DEVELOPMENT_DEPLOYMENT.md
```

### Production Files
```
├── deployment.yaml              # App deployment
├── service-production.yaml      # ClusterIP service
├── ingress-production.yaml      # Basic Ingress
├── ingress-production-ssl.yaml  # SSL Ingress
├── deploy-production.sh         # Production deploy script
├── setup-ssl.sh               # SSL setup guide
└── PRODUCTION_DEPLOYMENT.md
```

## 🚀 Quick Commands

### Development
```bash
# Deploy
./deploy.sh

# Access
curl http://kz-node.local:30008

# Check status
microk8s kubectl get all
```

### Production
```bash
# Deploy
./deploy-production.sh

# Access
curl -k https://srv642680.hstgr.cloud:448

# Check status
microk8s kubectl get ingress
```

## 🔧 Configuration Differences

### Service Configuration

**Development (service.yaml):**
```yaml
type: NodePort
ports:
  - targetPort: 8008
    port: 80
    nodePort: 30008
```

**Production (service-production.yaml):**
```yaml
type: ClusterIP
ports:
  - targetPort: 8008
    port: 80
```

### Network Access

**Development:**
- Direct access via NodePort
- No SSL required
- Local DNS resolution

**Production:**
- Access via Ingress controller
- SSL encryption required
- Domain name resolution

## 🔄 Switching Environments

### Development → Production
```bash
# Stop development service
microk8s kubectl delete -f service.yaml

# Deploy production
./deploy-production.sh
```

### Production → Development
```bash
# Stop production
microk8s kubectl delete -f ingress-production.yaml
microk8s kubectl delete -f service-production.yaml

# Deploy development
./deploy.sh
```

## 📊 Monitoring Differences

### Development Monitoring
```bash
# Check pods
microk8s kubectl get pods

# Check services
microk8s kubectl get services

# View logs
microk8s kubectl logs -f -l app=kz-node
```

### Production Monitoring
```bash
# Check ingress
microk8s kubectl get ingress

# Check SSL certificates
microk8s kubectl get secrets

# View ingress logs
microk8s kubectl logs -n ingress nginx-ingress-microk8s-controller-*
```

## 🛠️ Troubleshooting

### Development Issues
- DNS not resolving → Run `./setup-local-dns.sh`
- Port not accessible → Check NodePort service
- Pods not ready → Check deployment status

### Production Issues
- SSL certificate errors → Use `-k` flag or fix certificates
- Domain not resolving → Check DNS configuration
- Port 448 not accessible → Check firewall rules

## 🎯 Best Practices

### Development
- Use local DNS for consistent access
- Monitor resource usage
- Keep logs visible for debugging
- Use NodePort for direct access

### Production
- Use proper SSL certificates
- Monitor ingress controller
- Set up proper DNS
- Use Ingress for traffic management 