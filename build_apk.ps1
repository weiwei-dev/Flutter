# Flutter APK Build Script with Auto Version Update
param([switch]$Release, [switch]$NoVersionUpdate)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter APK Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Update version
if (-not $NoVersionUpdate) {
    Write-Host "Updating version..." -ForegroundColor Cyan
    & dart tools\update_version.dart
    if ($LASTEXITCODE -ne 0) { exit 1 }
    Write-Host ""
}

# Set build mode
$mode = if ($Release) { "--release" } else { "--debug" }

Write-Host "Building APK ($mode)..." -ForegroundColor Cyan

# Run flutter build using cmd to ensure environment variables are passed
# This avoids sqlite3 precompiled assets download issues
$cmdCommand = "set SQLITE3_NO_PRECOMPILED=1 && set NATIVE_TOOLCHAIN_C_OFFLINE=1 && set HOOKS_OFFLINE=1 && flutter build apk $mode"
$proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmdCommand -Wait -PassThru -NoNewWindow

if ($proc.ExitCode -eq 0) {
    Write-Host ""
    Write-Host "Build Success!" -ForegroundColor Green

    $verLine = Select-String -Path "pubspec.yaml" -Pattern "^version:" | Select-Object -First 1
    if ($verLine) { Write-Host "Version: $($verLine.Line.Trim())" -ForegroundColor Green }

    $path = if ($Release) { ".\build\app\outputs\flutter-apk\app-release.apk" } else { ".\build\app\outputs\flutter-apk\app-debug.apk" }
    if (Test-Path $path) {
        $size = (Get-Item $path).Length / 1MB
        Write-Host "APK: $path" -ForegroundColor Green
        Write-Host "Size: $([math]::Round($size, 2)) MB" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "Build Failed!" -ForegroundColor Red
    exit 1
}
