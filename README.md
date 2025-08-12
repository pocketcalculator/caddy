# 🚀 Custom Caddy with Cloudflare DNS Plugin

A production-ready Docker image of Caddy web server with the Cloudflare DNS plugin for automatic SSL certificate generation via DNS challenges.

## 🌟 Features

- **Caddy v2** with Cloudflare DNS plugin
- **Automatic HTTPS** via Let's Encrypt with DNS-01 challenges
- **Multi-stage Docker build** for optimal image size (135MB)
- **Production-ready** with security headers and logging
- **Docker Compose** support for easy deployment
- **GitHub Container Registry** integration

## 📦 Available Images

- **Registry**: `ghcr.io/pocketcalculator/caddy-cf:latest`
- **Size**: ~135MB
- **Architecture**: linux/amd64

## 🚀 Quick Start

### Prerequisites

1. **Cloudflare API Token** with permissions:
   - `Zone:Zone:Read`
   - `Zone:DNS:Edit`
   - Create at: https://dash.cloudflare.com/profile/api-tokens

2. **Docker** and **Docker Compose** installed

### Deployment

1. **Clone this repository**:
   ```bash
   git clone https://github.com/pocketcalculator/caddy.git
   cd caddy
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your real values
   ```

3. **Deploy with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

4. **Or run directly**:
   ```bash
   docker run -d \\
     --name caddy \\
     -p 80:80 -p 443:443 -p 2019:2019 \\
     -e CLOUDFLARE_API_TOKEN="your-token" \\
     -e DOMAIN="yourdomain.com" \\
     -e CADDY_ACME_EMAIL="your-email@domain.com" \\
     ghcr.io/pocketcalculator/caddy-cf:latest
   ```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token (required) | - |
| `DOMAIN` | Your domain name | `localhost` |
| `CADDY_ACME_EMAIL` | Email for ACME account | `admin@example.com` |

### Caddyfile

The default Caddyfile (`Caddyfile-cloudflare`) includes:
- Automatic HTTPS with Cloudflare DNS challenges
- Security headers
- Health check endpoint (`/health`)
- Static file serving
- HTTP to HTTPS redirects

## 🏗️ Building

To build the image locally:

```bash
./build-caddy.sh
```

To test the built image:

```bash
./test-with-cloudflare.sh
```

To push to GitHub Container Registry:

```bash
./push-to-registry.sh
```

## 📁 Project Structure

```
.
├── Dockerfile.cloudflare      # Multi-stage Docker build
├── Caddyfile-cloudflare       # Caddy configuration
├── docker-compose.yml         # Docker Compose setup
├── build-caddy.sh            # Build script
├── test-caddy.sh             # Comprehensive test suite
├── test-with-cloudflare.sh   # Cloudflare-specific tests
├── push-to-registry.sh       # Registry push script
├── setup-github-registry.sh  # GitHub registry setup
├── html/                     # Static content
├── .env.example              # Environment template
└── DEPLOYMENT.md             # Detailed deployment guide
```

## 🔍 Testing

The project includes comprehensive testing:

- **Container health checks**
- **HTTP/HTTPS functionality**
- **Cloudflare DNS plugin verification**
- **SSL certificate generation**
- **Admin API access**
- **Performance testing**

Run tests with:
```bash
./test-caddy.sh
```

## 🌐 Admin API

Access the Caddy admin API at:
- **Local**: http://localhost:2019/
- **Config**: http://localhost:2019/config/
- **Metrics**: http://localhost:2019/metrics

## 🛡️ Security

- Runs as non-root user (`caddy:caddy`)
- Security headers enabled
- Admin API can be restricted to localhost
- Secrets managed via environment variables
- Regular security updates via automated builds

## 📊 Monitoring

- Health check endpoint: `/health`
- Prometheus metrics: `:2019/metrics`
- Structured JSON logging
- Docker health checks included

## 🔄 Updates

To update to a newer version:

```bash
docker-compose pull
docker-compose up -d
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details.

## 🆘 Support

- **Issues**: https://github.com/pocketcalculator/caddy/issues
- **Discussions**: https://github.com/pocketcalculator/caddy/discussions
- **Caddy Docs**: https://caddyserver.com/docs/
- **Cloudflare API**: https://developers.cloudflare.com/api/

## 🏷️ Tags

`caddy` `docker` `cloudflare` `ssl` `https` `reverse-proxy` `web-server` `dns-challenge` `lets-encrypt` `automation`
