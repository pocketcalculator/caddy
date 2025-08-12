# 🚀 Caddy with Cloudflare DNS - Deployment Guide

## Next Steps After Building Your Custom Caddy Image

### 1. 📋 Pre-Deployment Checklist

✅ **Image Built Successfully**: `caddy-cf:test`  
✅ **Cloudflare DNS Plugin**: Loaded and working  
✅ **Local Testing**: Container runs and serves content  
✅ **SSL Certificates**: Generate properly via Cloudflare DNS  

### 2. 🏷️ Registry Options

Choose where to push your image:

#### Option A: Docker Hub (docker.io)
- **Free**: Public repositories
- **Paid**: Private repositories
- **Usage**: `docker.io/pocketcalculator/caddy-cf:latest`

#### Option B: GitHub Container Registry (ghcr.io)
- **Free**: Public and private repositories
- **Usage**: `ghcr.io/pocketcalculator/caddy-cf:latest`

#### Option C: Private Registry
- **Self-hosted**: Harbor, GitLab Registry, etc.
- **Cloud**: AWS ECR, Azure ACR, Google GCR

### 3. 🔐 Registry Setup

#### For Docker Hub:
```bash
# Login to Docker Hub
docker login docker.io

# Update push-to-registry.sh if needed
./push-to-registry.sh
```

#### For GitHub Container Registry:
```bash
# Create GitHub Personal Access Token with packages:write scope
# Login with token
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u USERNAME --password-stdin

# Update push-to-registry.sh:
# REGISTRY="ghcr.io"
# NAMESPACE="yourgithubusername"
```

### 4. 📤 Push to Registry

```bash
# Make push script executable
chmod +x push-to-registry.sh

# Push the image (will tag test -> latest)
./push-to-registry.sh

# Or specify version explicitly
./push-to-registry.sh test
```

### 5. 🌐 Production Deployment Options

#### Option A: Docker Compose (Recommended)
```bash
# 1. Copy your files to production server
scp -r . user@server:/opt/caddy/

# 2. Create production .env file
cp .env.example .env
# Edit .env with real values

# 3. Update docker-compose.yml to use registry image
# image: docker.io/pocketcalculator/caddy-cf:latest

# 4. Deploy
docker-compose up -d
```

#### Option B: Direct Docker Run
```bash
docker run -d \
  --name caddy-production \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -p 2019:2019 \
  -e CLOUDFLARE_API_TOKEN="your-real-token" \
  -e DOMAIN="yourdomain.com" \
  -e CADDY_ACME_EMAIL="your-email@domain.com" \
  -v caddy_data:/data \
  -v caddy_config:/config \
  docker.io/pocketcalculator/caddy-cf:latest
```

#### Option C: Kubernetes
```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: caddy-cloudflare
spec:
  replicas: 1
  selector:
    matchLabels:
      app: caddy
  template:
    metadata:
      labels:
        app: caddy
    spec:
      containers:
      - name: caddy
        image: docker.io/pocketcalculator/caddy-cf:latest
        ports:
        - containerPort: 80
        - containerPort: 443
        - containerPort: 2019
        env:
        - name: CLOUDFLARE_API_TOKEN
          valueFrom:
            secretKeyRef:
              name: cloudflare-secret
              key: api-token
        - name: DOMAIN
          value: "yourdomain.com"
        - name: CADDY_ACME_EMAIL
          value: "your-email@domain.com"
        volumeMounts:
        - name: caddy-data
          mountPath: /data
        - name: caddy-config
          mountPath: /config
      volumes:
      - name: caddy-data
        persistentVolumeClaim:
          claimName: caddy-data-pvc
      - name: caddy-config
        persistentVolumeClaim:
          claimName: caddy-config-pvc
```

### 6. 🔧 Production Configuration

#### Update Caddyfile for Production
```caddyfile
{
    # Admin API - restrict access in production
    admin 0.0.0.0:2019  # or localhost:2019 for security
    
    # Production email
    email {$CADDY_ACME_EMAIL}
    
    # Use Cloudflare DNS
    acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
    
    # Production logging
    log {
        output file /var/log/caddy/access.log
        format json
    }
}

# Production sites
{$DOMAIN} {
    root * /usr/share/caddy
    file_server
    
    # Security headers
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
    
    # Rate limiting (optional)
    rate_limit {
        zone static_files {
            key {remote_host}
            window 1m
            rate 100
        }
    }
    
    # Monitoring
    log {
        output file /var/log/caddy/access.log
        format json
    }
}
```

### 7. 📊 Monitoring & Maintenance

#### Health Checks
```bash
# Container health
docker ps
docker logs caddy-production

# Service health  
curl -f https://yourdomain.com/health

# Certificate status
curl -I https://yourdomain.com/
```

#### Backup Important Data
```bash
# Backup certificate data
docker run --rm -v caddy_data:/data -v $(pwd):/backup alpine tar czf /backup/caddy-data-backup.tar.gz -C /data .

# Backup configuration
docker run --rm -v caddy_config:/config -v $(pwd):/backup alpine tar czf /backup/caddy-config-backup.tar.gz -C /config .
```

### 8. 🔄 Updates & CI/CD

#### Manual Updates
```bash
# Build new version
./build-caddy.sh

# Test new version
./test-with-cloudflare.sh

# Push to registry
./push-to-registry.sh

# Deploy to production
docker-compose pull && docker-compose up -d
```

#### Automated CI/CD (GitHub Actions Example)
```yaml
name: Build and Deploy Caddy
on:
  push:
    branches: [main]
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build image
      run: ./build-caddy.sh
    - name: Push to registry
      run: ./push-to-registry.sh
    - name: Deploy to production
      run: |
        ssh user@server "cd /opt/caddy && docker-compose pull && docker-compose up -d"
```

### 9. 🛡️ Security Considerations

- [ ] Use strong Cloudflare API tokens with minimal permissions
- [ ] Restrict admin API access (`admin localhost:2019`)
- [ ] Use secrets management for API tokens
- [ ] Enable firewall rules for ports 80, 443, 2019
- [ ] Regular security updates
- [ ] Monitor logs for suspicious activity

### 10. 🚀 Ready to Deploy!

Your custom Caddy image is production-ready. Choose your deployment method and push to production!

#### Quick Start:
```bash
# 1. Push to registry
./push-to-registry.sh

# 2. Deploy with docker-compose
docker-compose up -d

# 3. Verify deployment
curl -I https://yourdomain.com/
```
