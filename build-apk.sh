#!/bin/bash

# Flutter APK Build Script using Docker
# This script builds the Flutter Android APK using Docker

set -e

echo "================================"
echo "Flutter APK Builder"
echo "================================"
echo ""

# Create dist directory if it doesn't exist
mkdir -p dist

echo "Building Docker image..."
docker build -t fileserveapp-builder .

echo ""
echo "Running container to build APK..."
docker run --rm -v "$(pwd)/dist:/dist" fileserveapp-builder

echo ""
echo "================================"
echo "Build complete!"
echo "APK location: $(pwd)/dist/app-release.apk"
echo "================================"
