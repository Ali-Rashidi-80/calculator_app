# Production build verification for calculator_app (Web, APK, Windows, emulator).
# Uses D:\Dev toolchain; tiered download policy already applied by install scripts.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/run-production-builds.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/run-production-builds.ps1 -SkipApk

param(
    [string]$ProjectRoot = 'D:\0\calculator_app\calculator_app',
    [switch]$SkipApk,
    [switch]$SkipWeb,
    [switch]$SkipWindows,
    [switch]$SkipEmulator
)

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\toolchain-config.ps1"

Initialize-ToolchainSessionEnv
$userPub = [Environment]::GetEnvironmentVariable('PUB_HOSTED_URL', 'User')
$userStorage = [Environment]::GetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'User')
if ($userPub) { $env:PUB_HOSTED_URL = $userPub }
if ($userStorage) { $env:FLUTTER_STORAGE_BASE_URL = $userStorage }
if (-not $env:PUB_HOSTED_URL -or -not $env:FLUTTER_STORAGE_BASE_URL) {
    $pub = Select-PubStorageMirrors -Mode 'auto'
    if (-not $env:PUB_HOSTED_URL) { $env:PUB_HOSTED_URL = $pub.pub }
    if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = $pub.storage }
}
Write-GradleUserProperties -GradleUserHome $env:GRADLE_USER_HOME | Out-Null

$results = @()
function Record-BuildResult {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    $script:results += [pscustomobject]@{ Name = $Name; Ok = $Ok; Detail = $Detail }
    $label = if ($Ok) { 'OK' } else { 'SKIP/FAIL' }
    $color = if ($Ok) { 'Green' } else { 'Yellow' }
    Write-Host "[$label] $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "     $Detail" }
}

Set-Location $ProjectRoot

$fv = flutter --version 2>&1 | Select-Object -First 1
Record-BuildResult -Name 'flutter --version' -Ok $true -Detail $fv

flutter pub get 2>&1 | Out-Null
Record-BuildResult -Name 'flutter pub get' -Ok ($LASTEXITCODE -eq 0)

flutter test 2>&1 | Tee-Object -Variable testOutput | Out-Null
$testText = ($testOutput | Out-String)
$testOk = ($LASTEXITCODE -eq 0) -and ($testText -match 'All tests passed')
$testDetail = ($testText -split "`n" | Where-Object { $_ -match 'tests passed|Some tests failed|FAILED' } | Select-Object -Last 1)
if (-not $testDetail) { $testDetail = "exit $LASTEXITCODE" }
Record-BuildResult -Name 'flutter test' -Ok $testOk -Detail $testDetail.Trim()

flutter analyze 2>&1 | Tee-Object -Variable analyzeOutput | Out-Null
$analyzeText = ($analyzeOutput | Out-String)
$analyzeOk = ($LASTEXITCODE -eq 0) -and ($analyzeText -match 'No issues found')
Record-BuildResult -Name 'flutter analyze' -Ok $analyzeOk -Detail $(if ($analyzeOk) { 'No issues found' } else { 'analyze failed' })

if (-not $SkipWeb) {
    flutter build web --release 2>&1 | Out-Null
    $webOk = ($LASTEXITCODE -eq 0) -and (Test-Path 'build\web\index.html')
    Record-BuildResult -Name 'flutter build web --release' -Ok $webOk -Detail 'build/web/index.html'
}

if (-not $SkipApk) {
    flutter build apk --release 2>&1 | Out-Null
    $apkOk = $LASTEXITCODE -eq 0
    $apk = Get-ChildItem 'build\app\outputs\flutter-apk\app-release.apk' -ErrorAction SilentlyContinue
    if ($apk) {
        $detail = $apk.FullName
        $aapt = Join-Path $env:ANDROID_HOME 'build-tools\34.0.0\aapt.exe'
        if (Test-Path $aapt) {
            $badging = & $aapt dump badging $apk.FullName 2>&1 | Out-String
            $minOk = $badging -match "sdkVersion:\s*'27'"
            if (-not $minOk) { $apkOk = $false }
            $sdkLine = ($badging -split "`n" | Where-Object { $_ -match 'sdkVersion' } | Select-Object -First 1)
            if ($sdkLine) { $detail = "$detail | $($sdkLine.Trim())" }
        }
        Record-BuildResult -Name 'flutter build apk --release' -Ok $apkOk -Detail $detail
    } else {
        Record-BuildResult -Name 'flutter build apk --release' -Ok $false -Detail 'APK not found'
    }
}

if (-not $SkipWindows) {
    $winBuildDir = Join-Path $ProjectRoot 'build\windows'
    $cmakeCache = Join-Path $winBuildDir 'x64\CMakeCache.txt'
    if (Test-Path $cmakeCache) {
        $normRoot = ($ProjectRoot -replace '\\', '/').TrimEnd('/')
        $cacheText = Get-Content $cmakeCache -Raw -ErrorAction SilentlyContinue
        if ($cacheText -and $cacheText -notmatch [regex]::Escape($normRoot)) {
            Remove-Item $winBuildDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host '  cleaned stale Windows CMake cache (project path changed)' -ForegroundColor Yellow
        }
    }
    flutter build windows --release 2>&1 | Out-Null
    $winExe = Join-Path $ProjectRoot 'build\windows\x64\runner\Release\calculator_app.exe'
    $winOk = ($LASTEXITCODE -eq 0) -and (Test-Path $winExe)
    if ($winOk) {
        $sizeKb = [math]::Round((Get-Item $winExe).Length / 1KB, 0)
        Record-BuildResult -Name 'flutter build windows --release' -Ok $true -Detail "$winExe ($sizeKb KB)"
    } else {
        Record-BuildResult -Name 'flutter build windows --release' -Ok $false -Detail 'exe missing or build failed'
    }
}

if (-not $SkipEmulator) {
    $devices = flutter devices 2>&1 | Out-String
    $hasAndroid = $devices -match 'android|emulator'
    if ($hasAndroid) {
        $lines = ($devices -split "`n" | Where-Object { $_ -match 'android|emulator' } | Select-Object -First 2) -join ' | '
        Record-BuildResult -Name 'flutter devices (android/emulator)' -Ok $true -Detail $lines
    } else {
        Record-BuildResult -Name 'flutter devices (android/emulator)' -Ok $false -Detail 'No emulator or USB device'
    }
}

Write-Host ''
Write-Host '=== Production build summary ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$failCount = @($results | Where-Object { -not $_.Ok }).Count
exit $failCount
