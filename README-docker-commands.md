# Quick Reference Commands for Docker Image Management

## GitHub Actions Setup (Recommended)
1. Push your repository to GitHub
2. Go to GitHub repository Settings → Secrets and variables → Actions
3. Add these secrets:
   - QUAY_USERNAME: Your quay.io username
   - QUAY_PASSWORD: Your quay.io password or robot token
4. Push changes to main branch - images will auto-build!

## Local PowerShell Script Usage
# Build and push all images:
.\build-and-push-all.ps1

# Build only (no push):
.\build-and-push-all.ps1 -NoPush

# Custom registry:
.\build-and-push-all.ps1 -Registry "your-registry.com" -ImageName "your-name/minecraft-java"

## Docker Compose Usage
# Build all images locally:
docker-compose build

# Build specific image:
docker-compose build java21

# Push all after building:
docker-compose push

## Manual Docker Commands
# Build single image:
docker build -t quay.io/noxitechdk/minecraft-java:java21 -f java/21/Dockerfile java/

# Push single image:
docker push quay.io/noxitechdk/minecraft-java:java21

# Login to quay.io:
docker login quay.io

## Useful Commands
# List built images:
docker images | grep minecraft-java

# Remove all minecraft-java images:
docker rmi $(docker images quay.io/noxitechdk/minecraft-java -q)

# Build all with no cache:
docker-compose build --no-cache