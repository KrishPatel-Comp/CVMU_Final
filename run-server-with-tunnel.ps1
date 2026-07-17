# Run RupeeLens backend with tunnel (so APK/emulator can reach it)
# Usage: .\run-server-with-tunnel.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$BackendPath = Join-Path $ProjectRoot "mybackend"
$Port = 8000
$Subdomain = "rupee-lens-v2"

# Ensure we're in project root
if (-not (Test-Path (Join-Path $BackendPath "main.py"))) {
    Write-Error "Backend not found at $BackendPath. Run this script from the project root."
    exit 1
}

$VenvPython = Join-Path $BackendPath "venv\Scripts\python.exe"
$VenvUvicorn = Join-Path $BackendPath "venv\Scripts\uvicorn.exe"
if (-not (Test-Path $VenvUvicorn)) {
    Write-Error "Virtual env or uvicorn not found. Create venv and install: cd mybackend && python -m venv venv && .\venv\Scripts\pip install -r requirements.txt"
    exit 1
}

Write-Host "Starting FastAPI server on port $Port..." -ForegroundColor Cyan
# Start server in a new window so you can see logs
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$BackendPath'; & '$VenvUvicorn' main:app --host 0.0.0.0 --port $Port"
$ServerProcess = $true

# Wait for server to be ready
Write-Host "Waiting for server to be ready..." -ForegroundColor Yellow
$maxAttempts = 15
$attempt = 0
do {
    Start-Sleep -Seconds 1
    $attempt++
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        break
    } catch {
        if ($attempt -ge $maxAttempts) {
            Write-Error "Server did not start in time. Check the server window for errors."
            exit 1
        }
    }
} while ($true)

Write-Host "Server is up. Starting tunnel (subdomain: $Subdomain)..." -ForegroundColor Green
Write-Host "APK base URL: https://${Subdomain}.loca.lt" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the tunnel (server window will stay open).`n" -ForegroundColor Gray

# Run tunnel in this window (user sees URL here)
try {
    & npx --yes localtunnel --port $Port --subdomain $Subdomain
} catch {
    Write-Host "`nIf subdomain is taken, run without it and update lib/core/services/api_service.dart baseUrl:" -ForegroundColor Yellow
    Write-Host "  npx localtunnel --port $Port" -ForegroundColor Yellow
}
Write-Host "`nTunnel stopped. Close the server window when done." -ForegroundColor Gray
