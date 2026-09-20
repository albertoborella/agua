#!/bin/bash
# build.sh - Build and run Agua backend with Podman

set -e

IMAGE_NAME="agua-backend"
CONTAINER_NAME="agua-backend"

echo "🔨 Building image..."
podman build -t $IMAGE_NAME -f Containerfile .

echo "🚀 Stopping existing container (if any)..."
podman rm -f $CONTAINER_NAME 2>/dev/null || true

echo "🏃 Running container..."
podman run -d \
    --name $CONTAINER_NAME \
    -p 8000:8000 \
    -v agua-data:/app/data:Z \
    -e JWT_SECRET="${JWT_SECRET:-dev-secret-change-in-production}" \
    -e ENVIRONMENT="${ENVIRONMENT:-development}" \
    $IMAGE_NAME

echo "✅ Container started!"
echo "   URL: http://localhost:8000"
echo "   Docs: http://localhost:8000/docs"
echo "   Health: http://localhost:8000/health"
echo ""
echo "📋 Useful commands:"
echo "   podman logs $CONTAINER_NAME"
echo "   podman exec -it $CONTAINER_NAME bash"
echo "   podman stop $CONTAINER_NAME"
