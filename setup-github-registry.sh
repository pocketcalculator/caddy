#!/bin/bash

# GitHub Container Registry Setup Guide
# This script helps you set up authentication for GitHub Container Registry

echo "🐙 GitHub Container Registry Setup"
echo "=================================="
echo ""
echo "You need a GitHub Personal Access Token (PAT) to push images."
echo ""
echo "📋 Steps to create a PAT:"
echo "1. Go to: https://github.com/settings/tokens"
echo "2. Click 'Generate new token' → 'Generate new token (classic)'"
echo "3. Set expiration (recommend 90 days or 1 year)"
echo "4. Select these scopes:"
echo "   ✅ write:packages (allows pushing to registry)"
echo "   ✅ read:packages (allows pulling from registry)"
echo "   ✅ delete:packages (optional - allows deleting images)"
echo "5. Click 'Generate token'"
echo "6. Copy the token (you won't see it again!)"
echo ""

read -p "Press Enter when you have your token ready..."

echo ""
echo "🔐 Now login to GitHub Container Registry:"
echo "Enter your GitHub username and the token as password"
echo ""

# Login to GitHub Container Registry
docker login ghcr.io

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully logged in to GitHub Container Registry!"
    echo ""
    echo "🚀 You can now push your image:"
    echo "   ./push-to-registry.sh"
    echo ""
    echo "📖 Your image will be available at:"
    echo "   ghcr.io/stereo2go/caddy-cf:latest"
    echo ""
    echo "🔄 To make it public (optional):"
    echo "1. Go to: https://github.com/stereo2go?tab=packages"
    echo "2. Click on your 'caddy-cf' package"
    echo "3. Go to 'Package settings'"
    echo "4. Change visibility to 'Public'"
else
    echo ""
    echo "❌ Login failed. Please check your credentials and try again."
    echo ""
    echo "💡 Troubleshooting:"
    echo "- Make sure you're using your GitHub username (not email)"
    echo "- Use the Personal Access Token as the password (not your GitHub password)"
    echo "- Ensure the token has 'write:packages' scope"
fi
