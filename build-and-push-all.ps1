# PowerShell script to build and push all Java Docker images to Quay.io
# Usage: .\build-and-push-all.ps1

param(
    [string]$Registry = "quay.io",
    [string]$ImageName = "noxitechdk/minecraft-java",
    [switch]$NoPush = $false
)

# Java versions to build
$JavaVersions = @(7, 8, 11, 16, 17, 18, 19, 21, 22, 23, 24)

Write-Host "🚀 Starting build and push process for all Java versions..." -ForegroundColor Green
Write-Host "Registry: $Registry" -ForegroundColor Cyan
Write-Host "Image name: $ImageName" -ForegroundColor Cyan
Write-Host "Push enabled: $(-not $NoPush)" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker version | Out-Null
} catch {
    Write-Error "Docker is not running or not installed. Please start Docker Desktop."
    exit 1
}

# Check if logged into quay.io (unless NoPush is specified)
if (-not $NoPush) {
    Write-Host "🔐 Checking Quay.io login status..." -ForegroundColor Yellow
    $loginCheck = docker login $Registry --username test --password test 2>&1
    if ($loginCheck -like "*unauthorized*" -or $loginCheck -like "*denied*") {
        Write-Host "❌ Not logged into $Registry. Please run: docker login $Registry" -ForegroundColor Red
        exit 1
    }
}

$successCount = 0
$failedVersions = @()

foreach ($version in $JavaVersions) {
    Write-Host ""
    Write-Host "🔨 Building Java $version..." -ForegroundColor Yellow
    
    $dockerfilePath = ".\java\$version\Dockerfile"
    $imageName = "$Registry/${ImageName}:java$version"
    $latestTag = "$Registry/${ImageName}:java$version-latest"
    
    # Check if Dockerfile exists
    if (-not (Test-Path $dockerfilePath)) {
        Write-Host "❌ Dockerfile not found at $dockerfilePath" -ForegroundColor Red
        $failedVersions += $version
        continue
    }
    
    try {
        # Build the image
        Write-Host "Building $imageName..." -ForegroundColor Cyan
        docker build -t $imageName -t $latestTag -f $dockerfilePath .\java
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed"
        }
        
        if (-not $NoPush) {
            # Push the image
            Write-Host "Pushing $imageName..." -ForegroundColor Cyan
            docker push $imageName
            docker push $latestTag
            
            if ($LASTEXITCODE -ne 0) {
                throw "Docker push failed"
            }
            
            Write-Host "✅ Successfully built and pushed Java $version" -ForegroundColor Green
        } else {
            Write-Host "✅ Successfully built Java $version (push skipped)" -ForegroundColor Green
        }
        
        $successCount++
    }
    catch {
        Write-Host "❌ Failed to build/push Java $version`: $($_.Exception.Message)" -ForegroundColor Red
        $failedVersions += $version
    }
}

Write-Host ""
Write-Host "📊 Build Summary:" -ForegroundColor Magenta
Write-Host "Successful: $successCount/$($JavaVersions.Count)" -ForegroundColor Green

if ($failedVersions.Count -gt 0) {
    Write-Host "Failed versions: $($failedVersions -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "🎉 All images built and pushed successfully!" -ForegroundColor Green
}