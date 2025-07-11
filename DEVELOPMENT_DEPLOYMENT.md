# Development Deployment Guide

## 🚀 Quick Start

1. **Deploy to development:**
   ```bash
   ./deploy.sh
   ```

2. **Access your app:**
   - URL: `http://kz-node.local:30008`
   - Test: `curl http://kz-node.local:30008`

## 📁 Files Overview

### Core Files
- `deployment.yaml` - Your application deployment
- `service.yaml` - Development service (NodePort)
- `nginx.yaml` - Optional nginx service

### Scripts
- `deploy.sh` - Deploy everything to development
- `get-url.sh` - Get current service URL
- `setup-local-dns.sh` - Set up local DNS entry

## 🔧 Configuration Options

### Option 1: Local DNS (Recommended)
```bash
# Set up local DNS entry
./setup-local-dns.sh

# Access via hostname
curl http://kz-node.local:30008
```

### Option 2: Direct IP Access
```bash
# Get current node IP
./get-url.sh

# Access via IP
curl http://192.168.64.2:30008
```

### Option 3: LoadBalancer (Alternative)
```bash
# Use LoadBalancer service
kubectl apply -f service-loadbalancer.yaml

# Access via LoadBalancer IP
curl http://192.168.1.240
```

## 🌐 Network Configuration

### Development Service
- **Type**: NodePort
- **Port**: 30008 (external) → 80 (internal) → 8008 (container)
- **Access**: Direct from localhost

### Local DNS Setup
- **Hostname**: `kz-node.local`
- **IP**: Automatically resolves to node IP
- **Port**: 30008

## 🔍 Troubleshooting

### Check Status
```bash
# Check pods
microk8s kubectl get pods

# Check services
microk8s kubectl get services

# Check node IP
microk8s kubectl get nodes -o wide
```

### Common Issues

#### 1. DNS Not Working
```bash
# Check if hostname is in /etc/hosts
cat /etc/hosts | grep kz-node

# Re-run DNS setup
./setup-local-dns.sh
```

#### 2. Port Not Accessible
```bash
# Check if service is running
microk8s kubectl get services

# Check if pods are ready
microk8s kubectl get pods

# Check application logs
microk8s kubectl logs -l app=kz-node
```

#### 3. LoadBalancer Not Working
```bash
# Check MetalLB status
microk8s status

# Re-enable MetalLB if needed
microk8s enable metallb
```

## 📊 Monitoring

### Health Check
```bash
# Test application
curl http://kz-node.local:30008
# Expected: "Kzen drive"

# Check pod status
microk8s kubectl get pods -o wide
```

### Logs
```bash
# Application logs
microk8s kubectl logs -l app=kz-node

# Specific pod logs
microk8s kubectl logs <pod-name>

# Follow logs in real-time
microk8s kubectl logs -f -l app=kz-node
```

## 🔄 Development Workflow

### Hot Reload (if supported)
```bash
# Watch for changes
microk8s kubectl get pods -w

# Restart deployment
microk8s kubectl rollout restart deployment kz-node
```

### Scaling
```bash
# Scale up for testing
microk8s kubectl scale deployment kz-node --replicas=8

# Scale down
microk8s kubectl scale deployment kz-node --replicas=1
```

### Image Updates
```bash
# Update image
microk8s kubectl set image deployment/kz-node kz-node=andygr1n1/kz-node:latest

# Or edit deployment
microk8s kubectl edit deployment kz-node
```

## 🛠️ Development Tools

### Port Forwarding (Alternative)
```bash
# Forward port directly to pod
microk8s kubectl port-forward deployment/kz-node 8080:8008

# Access via localhost
curl http://localhost:8080
```

### Debug Mode
```bash
# Get into a pod
microk8s kubectl exec -it <pod-name> -- /bin/bash

# Check container resources
microk8s kubectl top pods
```

### Resource Monitoring
```bash
# Check resource usage
microk8s kubectl describe pods

# Check events
microk8s kubectl get events --sort-by='.lastTimestamp'
```

## 🔧 Environment Variables

### Add Environment Variables
```bash
# Edit deployment
microk8s kubectl edit deployment kz-node

# Or apply updated deployment
microk8s kubectl apply -f deployment.yaml
```

### Example Environment Setup
```yaml
# In deployment.yaml
env:
- name: NODE_ENV
  value: "development"
- name: DEBUG
  value: "true"
```

## 📝 Development Best Practices

### 1. Use Local DNS
- Always use `kz-node.local:30008` for consistent access
- Run `./setup-local-dns.sh` after cluster restarts

### 2. Monitor Resources
- Keep an eye on pod status and logs
- Use `microk8s kubectl top pods` for resource monitoring

### 3. Quick Debugging
```bash
# Check everything at once
microk8s kubectl get all

# Check specific resource
microk8s kubectl describe service kz-node
microk8s kubectl describe pod <pod-name>
```

### 4. Clean Up
```bash
# Delete everything
microk8s kubectl delete -f deployment.yaml
microk8s kubectl delete -f service.yaml

# Or delete by label
microk8s kubectl delete all -l app=kz-node
```

## 🎯 Quick Commands Reference

```bash
# Deploy
./deploy.sh

# Get URL
./get-url.sh

# Setup DNS
./setup-local-dns.sh

# Check status
microk8s kubectl get all

# View logs
microk8s kubectl logs -f -l app=kz-node

# Restart
microk8s kubectl rollout restart deployment kz-node

# Scale
microk8s kubectl scale deployment kz-node --replicas=4
```

## 🔄 Switching Between Environments

### Development → Production
```bash
# Stop development
microk8s kubectl delete -f service.yaml

# Deploy to production
./deploy-production.sh
```

### Production → Development
```bash
# Stop production
microk8s kubectl delete -f ingress-production.yaml
microk8s kubectl delete -f service-production.yaml

# Deploy to development
./deploy.sh
``` 