#!/bin/bash

# Test Caddy with Cloudflare API Token
# This script runs the container with your Cloudflare credentials

set -e

# Configuration
IMAGE_NAME="caddy-cf:test"
CONTAINER_NAME="caddy-cf-test"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Testing Caddy with Cloudflare DNS Plugin${NC}"
echo "================================================"

# Check if required environment variables are set
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo -e "${RED}❌ Error: CLOUDFLARE_API_TOKEN environment variable is not set${NC}"
    echo ""
    echo "Please set your Cloudflare API token:"
    echo "export CLOUDFLARE_API_TOKEN='your-token-here'"
    echo ""
    echo "To get a Cloudflare API token:"
    echo "1. Go to https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Create a token with 'Zone:Zone:Read' and 'Zone:DNS:Edit' permissions"
    echo "3. Set the token to your specific zone(s)"
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}⚠️  Warning: DOMAIN environment variable not set${NC}"
    echo "Using localhost for testing. For real SSL certificates, set:"
    echo "export DOMAIN='yourdomain.com'"
    echo ""
    DOMAIN="localhost"
fi

if [ -z "$CADDY_ACME_EMAIL" ]; then
    echo -e "${YELLOW}⚠️  Warning: CADDY_ACME_EMAIL not set, using default${NC}"
    CADDY_ACME_EMAIL="admin@example.com"
fi

echo "Configuration:"
echo "  Domain: $DOMAIN"
echo "  Email: $CADDY_ACME_EMAIL"
echo "  Token: ${CLOUDFLARE_API_TOKEN:0:10}..." # Show only first 10 chars
echo ""

# Cleanup any existing container
echo "🧹 Cleaning up any existing containers..."
docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
docker rm $CONTAINER_NAME >/dev/null 2>&1 || true

# Run the container with Cloudflare credentials
echo "🏃 Starting Caddy container with Cloudflare integration..."
docker run -d \
    --name $CONTAINER_NAME \
    -p 8080:80 \
    -p 8443:443 \
    -p 2019:2019 \
    -e CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
    -e DOMAIN="$DOMAIN" \
    -e CADDY_ACME_EMAIL="$CADDY_ACME_EMAIL" \
    $IMAGE_NAME

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 5

# Check if container is running
if docker ps | grep -q $CONTAINER_NAME; then
    echo -e "${GREEN}✅ Container is running successfully!${NC}"
else
    echo -e "${RED}❌ Container failed to start${NC}"
    echo "Container logs:"
    docker logs $CONTAINER_NAME
    exit 1
fi

# Test basic functionality
echo ""
echo "🧪 Testing basic functionality..."

# Test health endpoint
echo "Testing health endpoint..."
if curl -s http://localhost:8080/health | grep -q "OK"; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${RED}❌ Health check failed${NC}"
fi

# Test if Cloudflare module is loaded
echo "Checking if Cloudflare DNS module is loaded..."
if docker exec $CONTAINER_NAME caddy list-modules | grep -q "cloudflare"; then
    echo -e "${GREEN}✅ Cloudflare DNS module is loaded${NC}"
else
    echo -e "${RED}❌ Cloudflare DNS module not found${NC}"
fi

# Show container logs for debugging
echo ""
echo "📝 Container logs (last 20 lines):"
docker logs --tail 20 $CONTAINER_NAME

echo ""
echo -e "${GREEN}🎉 Test completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Test with a real domain: DOMAIN=yourdomain.com ./test-with-cloudflare.sh"
echo "2. Monitor logs: docker logs -f $CONTAINER_NAME"
echo "3. Stop container: docker stop $CONTAINER_NAME"
echo ""
echo "URLs to test:"
echo "  HTTP:  http://localhost:8080/"
echo "  HTTPS: https://localhost:8443/ (self-signed for localhost)"
echo "  Admin: http://localhost:2019/"
