# Quick Reference Commands for Docker Image Management

## GitHub Container Registry Setup (Recommended - No secrets needed!)
1. Push your repository to GitHub
2. GitHub Actions automatically builds and pushes to ghcr.io
3. No manual setup required - uses GITHUB_TOKEN automatically!

## Local PowerShell Script Usage
# Build and push all images:
.\build-and-push-all.ps1

# Build only (no push):
.\build-and-push-all.ps1 -NoPush

# Login to GitHub Container Registry first:
docker login ghcr.io -u YOUR_GITHUB_USERNAME

## Docker Compose Usage
# Build all images locally:
docker-compose build

# Build specific image:
docker-compose build java21

# Push all after building:
docker-compose push

## Manual Docker Commands
# Build single image:
docker build -t ghcr.io/noxitechdk/minecraft-java:java21 -f java/21/Dockerfile java/

# Push single image:
docker push ghcr.io/noxitechdk/minecraft-java:java21

# Login to GitHub Container Registry:
docker login ghcr.io -u YOUR_GITHUB_USERNAME

## Using the images
# Pull and use:
docker pull ghcr.io/noxitechdk/minecraft-java:java21
docker run ghcr.io/noxitechdk/minecraft-java:java21

## Useful Commands
# List built images:
docker images | grep minecraft-java

# Remove all minecraft-java images:
docker rmi $(docker images ghcr.io/noxitechdk/minecraft-java -q)

# Build all with no cache:
docker-compose build --no-cache