#!/bin/bash
set -e

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 [local|push] [version]"
    echo "  local   - Local test build (only build current platform and load locally)"
    echo "  push    - Multi-platform build and push to registry"
    echo "  version - Optional version tag (e.g., 2.8.4), defaults to latest Caddy version"
    exit 1
fi

MODE=$1

# Get latest Caddy version from GitHub API if no version specified
if [ -z "$2" ]; then
    echo "Fetching latest Caddy version..."
    CADDY_VERSION=$(curl -s https://api.github.com/repos/caddyserver/caddy/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [ -z "$CADDY_VERSION" ]; then
        echo "Warning: Failed to fetch Caddy version, using 'latest' as fallback"
        VERSION="latest"
    else
        VERSION="$CADDY_VERSION"
        echo "Latest Caddy version: v$CADDY_VERSION"
    fi
else
    VERSION="$2"
fi

echo "Build mode: $MODE"
echo "Build version: $VERSION"

# Setup docker buildx
if ! docker buildx inspect mybuilder > /dev/null 2>&1; then
  echo "Creating buildx builder instance..."
  docker buildx create --name mybuilder --use
else
  docker buildx use mybuilder
fi

# Create release directory if it doesn't exist
mkdir -p release

echo "Starting image build..."

if [ "$MODE" = "local" ]; then
    echo "=== Local Test Build Mode ==="
    # Local test build, build for current platform and load locally
    PLATFORM="linux/$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')"
    echo "Build platform: $PLATFORM"
    
    # Build image and extract binary
    docker buildx build --platform $PLATFORM \
      -t palfans/caddy:latest \
      -t palfans/caddy:$VERSION \
      --load .
    
    # Extract caddy binary from image
    ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
    echo "Extracting caddy binary for $ARCH..."
    CONTAINER_ID=$(docker create palfans/caddy:latest)
    docker cp $CONTAINER_ID:/usr/bin/caddy release/caddy-$ARCH
    docker rm $CONTAINER_ID
    chmod +x release/caddy-$ARCH
    
    echo "✅ Local image build complete!"
    echo "   Binary saved to: release/caddy-$ARCH"
    echo "   You can test with:"
    echo "   docker run --rm -p 80:80 -p 443:443 palfans/caddy:latest"

elif [ "$MODE" = "push" ]; then
    echo "=== Multi-platform Build and Push Mode ==="
    
    # Build and push multi-platform images
    echo "Building and pushing images to registry..."
    docker buildx build --platform linux/arm64,linux/amd64 \
      -t palfans/caddy:latest \
      -t palfans/caddy:$VERSION \
      --push .
    
    # Extract binaries from both platforms
    echo "Extracting binaries for both platforms..."
    
    # Extract amd64 binary
    echo "Extracting amd64 binary..."
    docker pull --platform linux/amd64 palfans/caddy:$VERSION
    CONTAINER_ID=$(docker create --platform linux/amd64 palfans/caddy:$VERSION)
    docker cp $CONTAINER_ID:/usr/bin/caddy release/caddy-amd64
    docker rm $CONTAINER_ID
    chmod +x release/caddy-amd64
    
    # Extract arm64 binary
    echo "Extracting arm64 binary..."
    docker pull --platform linux/arm64 palfans/caddy:$VERSION
    CONTAINER_ID=$(docker create --platform linux/arm64 palfans/caddy:$VERSION)
    docker cp $CONTAINER_ID:/usr/bin/caddy release/caddy-arm64
    docker rm $CONTAINER_ID
    chmod +x release/caddy-arm64
    
    echo "✅ Multi-platform image build and push complete!"
    echo "   Pushed tags:"
    echo "   - palfans/caddy:latest"
    echo "   - palfans/caddy:$VERSION"
    echo "   Binaries saved to:"
    echo "   - release/caddy-amd64"
    echo "   - release/caddy-arm64"

else
    echo "Error: Unknown build mode '$MODE'"
    echo "Supported modes: local, push"
    exit 1
fi

echo "Build operation complete!"
