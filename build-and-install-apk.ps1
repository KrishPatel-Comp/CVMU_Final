# Build RupeeLens APK and install on connected device/emulator
# Prerequisites: Flutter in PATH, device/emulator connected (adb devices)
# Usage: .\build-and-install-apk.ps1   or   .\build-and-install-apk.ps1 -Debug

param(
    [switch]$Debug  # Build debug APK (default: release)
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$FlutterApp = Join-Path $ProjectRoot "rupeelens"

if (-not (Test-Path (Join-Path $FlutterApp "pubspec.yaml"))) {
    Write-Error "Flutter app not found at $FlutterApp. Run from project root."
    exit 1
}

Push-Location $FlutterApp
try {
    if ($Debug) {
        Write-Host "Building debug APK..." -ForegroundColor Cyan
        flutter build apk --debug
        $ApkPath = "build\app\outputs\flutter-apk\app-debug.apk"
    } else {
        Write-Host "Building release APK..." -ForegroundColor Cyan
        flutter build apk
        $ApkPath = "build\app\outputs\flutter-apk\app-release.apk"
    }

    if (-not (Test-Path $ApkPath)) {
        Write-Error "APK not found at $ApkPath"
        exit 1
    }

    $FullPath = (Resolve-Path $ApkPath).Path
    Write-Host "Installing $FullPath ..." -ForegroundColor Green
    & adb install -r $FullPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Install failed. Is a device/emulator connected? Run: adb devices" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Done. Open RupeeLens on your device." -ForegroundColor Green
} finally {
    Pop-Location
}
