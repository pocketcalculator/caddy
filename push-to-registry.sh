#!/bin/bash

# Docker Registry Push Script for Custom Caddy
# Pushes the custom Caddy image to Docker registry

set -e

# Configuration (matches build-caddy.sh)
IMAGE_NAME="caddy-cf"
VERSION="latest"
REGISTRY="ghcr.io"  # GitHub Container Registry
NAMESPACE="pocketcalculator"  # Your actual GitHub username

# Also support test version
LOCAL_VERSION=${1:-"test"}  # Use command line arg or default to "test"

# Full image names
LOCAL_IMAGE_NAME="${IMAGE_NAME}:${LOCAL_VERSION}"
FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${VERSION}"

echo "🚀 Pushing Custom Caddy with Cloudflare DNS to Docker Registry"
echo "============================================================="
echo "Registry: ${REGISTRY}"
echo "Local Image: ${LOCAL_IMAGE_NAME}"
echo "Remote Image: ${FULL_IMAGE_NAME}"
echo ""

# Check if image exists locally
if ! docker images | grep -q "${IMAGE_NAME}.*${LOCAL_VERSION}"; then
    echo "❌ Image ${LOCAL_IMAGE_NAME} not found locally!"
    echo "Please build the image first using: ./build-caddy.sh"
    echo "Available images:"
    docker images | grep caddy
    exit 1
fi

# Tag the local image for registry
echo "🏷️  Tagging image for registry..."
docker tag "${LOCAL_IMAGE_NAME}" "${FULL_IMAGE_NAME}"

# Login to registry (if needed)
echo "🔐 Logging into Docker registry..."
echo "Please enter your credentials when prompted:"
docker login ${REGISTRY}

if [ $? -ne 0 ]; then
    echo "❌ Failed to login to registry!"
    exit 1
fi

# Push the image
echo ""
echo "📤 Pushing image to registry..."
docker push "${FULL_IMAGE_NAME}"

if [ $? -eq 0 ]; then
    echo "✅ Push completed successfully!"
    echo ""
    echo "🎉 Your minimal Caddy image is now available at:"
    echo "   ${FULL_IMAGE_NAME}"
    echo ""
    echo "To pull and run from anywhere:"
    echo "   docker run -d \\"
    echo "     -p 80:80 -p 443:443 -p 2019:2019 \\"
    echo "     -e CLOUDFLARE_API_TOKEN=your-token \\"
    echo "     -e DOMAIN=yourdomain.com \\"
    echo "     -e CADDY_ACME_EMAIL=your-email@example.com \\"
    echo "     ${FULL_IMAGE_NAME}"
    echo ""
    echo "   Or use docker-compose with your .env file"
else
    echo "❌ Push failed!"
    exit 1
fi

# Optional: Create and push additional tags
read -p "🏷️  Do you want to create additional tags? (y/N): " create_tags
if [[ $create_tags =~ ^[Yy]$ ]]; then
    echo ""
    echo "Creating additional tags..."
    
    # Tag with current date
    DATE_TAG=$(date +%Y%m%d)
    docker tag "${FULL_IMAGE_NAME}" "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${DATE_TAG}"
    docker push "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${DATE_TAG}"
    
    # Tag with git commit (if in git repo)
    if git rev-parse --git-dir > /dev/null 2>&1; then
        GIT_COMMIT=$(git rev-parse --short HEAD)
        docker tag "${FULL_IMAGE_NAME}" "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${GIT_COMMIT}"
        docker push "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${GIT_COMMIT}"
        echo "✅ Additional tags pushed: ${DATE_TAG}, ${GIT_COMMIT}"
    else
        echo "✅ Additional tag pushed: ${DATE_TAG}"
    fi
fi

echo ""
echo "🎯 Summary:"
echo "   Registry: ${REGISTRY}"
echo "   Image: ${NAMESPACE}/${IMAGE_NAME}"
echo "   Tags pushed: latest"
if [[ $create_tags =~ ^[Yy]$ ]]; then
    echo "                ${DATE_TAG}"
    [[ -n $GIT_COMMIT ]] && echo "                ${GIT_COMMIT}"
fi
