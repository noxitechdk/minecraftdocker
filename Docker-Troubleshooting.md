# Docker Desktop Troubleshooting Guide

## Problem: "500 Internal Server Error for API route"
Dette er et kendt problem med Docker Desktop på Windows.

## Løsninger (prøv i denne rækkefølge):

### 1. Fuld genstart af Docker Desktop:
1. Højreklik på Docker Desktop ikonet i system tray
2. Vælg "Quit Docker Desktop"
3. Vent 30 sekunder
4. Start Docker Desktop igen
5. Vent på at den viser "Docker Desktop is running"

### 2. Reset Docker Desktop:
1. Åbn Docker Desktop
2. Gå til Settings (tandhjul øverst til højre)
3. Gå til "Troubleshoot" tab
4. Klik "Reset to factory defaults"
5. Genstart computer

### 3. WSL2 fix (hvis du bruger WSL2 backend):
Kør i PowerShell som Administrator:
```
wsl --shutdown
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data
```
Derefter genstart Docker Desktop

### 4. Container/VM restart:
I PowerShell som Administrator:
```
Restart-Service docker
# eller
net stop docker
net start docker
```

### 5. Skift til Windows containers (midlertidigt):
1. Højreklik Docker Desktop i system tray
2. "Switch to Windows containers..."
3. Vent på switch completion
4. "Switch to Linux containers..."

## Test efter hver løsning:
```
docker version
docker ps
```

Hvis du ser både Client og Server info uden fejl, virker Docker igen!