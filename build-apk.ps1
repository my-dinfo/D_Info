# 1-Click Build Script for Web and Android APK
$ErrorActionPreference = "Stop"

Write-Host ">>> [1/4] Building web assets to www/..." -ForegroundColor Cyan
if (!(Test-Path -Path "www")) {
    New-Item -ItemType Directory -Path "www" | Out-Null
}
Copy-Item "index.html" "www/index.html" -Force
Write-Host ">>> Web assets updated in www/index.html" -ForegroundColor Green

Write-Host ">>> [2/4] Syncing Capacitor Android assets..." -ForegroundColor Cyan
cmd.exe /c "npx.cmd cap sync android"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Capacitor sync failed"
    exit $LASTEXITCODE
}

Write-Host ">>> [3/4] Compiling Android Debug APK with Gradle..." -ForegroundColor Cyan
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$($env:JAVA_HOME)\bin;$($env:Path)"

Push-Location "android"
try {
    .\gradlew.bat assembleDebug
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Gradle build failed"
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

Write-Host ">>> [4/4] Copying final APK to project root..." -ForegroundColor Cyan
$builtApk = "android\app\build\outputs\apk\debug\app-debug.apk"
$targetApk = "app-debug.apk"

if (Test-Path $builtApk) {
    Copy-Item $builtApk $targetApk -Force
    $apkItem = Get-Item $targetApk
    $apkSizeMB = [math]::Round($apkItem.Length / 1MB, 2)
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " SUCCESS! APK Build Completed:" -ForegroundColor Green
    Write-Host " Location: $($apkItem.FullName)" -ForegroundColor Yellow
    Write-Host " Size: $apkSizeMB MB | Time: $($apkItem.LastWriteTime)" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Green
} else {
    Write-Error "APK file not found at $builtApk"
}
