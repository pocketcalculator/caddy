#!/bin/bash

# Caddy Docker Build Script (Cloudflare DNS plugin)
# Uses Dockerfile and tags image as caddy-cf:latest
# Based on official Caddy documentation: https://caddyserver.com/docs/build#docker

set -e

# Always run from this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
IMAGE_NAME="caddy-cf"
VERSION="latest"
REGISTRY="ghcr.io"  # GitHub Container Registry
NAMESPACE="pocketcalculator"  # Change this to your Docker Hub username or organization

# Full image name
FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${VERSION}"

echo "🏗️  Building Caddy Docker Image (Cloudflare plugin)"
echo "================================================"
echo "Plugins: cloudflare-dns"
echo "Image Name: ${FULL_IMAGE_NAME}"
echo "Build Context: $(pwd)"
echo ""

# Build the Docker image
echo "📦 Building Docker image..."
docker build \
    --file Dockerfile \
    --tag "${IMAGE_NAME}:${VERSION}" \
    --tag "${FULL_IMAGE_NAME}" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    .

if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
else
    echo "❌ Build failed!"
    exit 1
fi

# Display image information
echo ""
echo "📊 Image Information:"
docker images | grep "${IMAGE_NAME}"

# Get image size
IMAGE_SIZE=$(docker images --format "table {{.Size}}" "${IMAGE_NAME}:${VERSION}" | tail -n 1)
echo "📏 Image Size: ${IMAGE_SIZE}"

echo ""
echo "🚀 Build Complete!"
echo "Local image: ${IMAGE_NAME}:${VERSION}"
echo "Registry image: ${FULL_IMAGE_NAME}"
echo ""
echo "Next steps:"
echo "1. Test the image: (see ./test-caddy.sh)"
echo "2. Push to registry: docker push ${FULL_IMAGE_NAME}"
echo "3. Run test suite: ./test-caddy.sh"
