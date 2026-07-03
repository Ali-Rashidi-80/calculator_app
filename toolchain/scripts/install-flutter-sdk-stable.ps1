# Download/extract latest Flutter stable; auto-upgrade on each run when newer stable exists.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-flutter-sdk-stable.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-flutter-sdk-stable.ps1 -Force

param(
    [string]$FlutterRoot = $null,
    [switch]$SkipExtract,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\toolchain-config.ps1"

if (-not $FlutterRoot) { $FlutterRoot = $script:DefaultFlutterRoot }
Ensure-DevDirectories

Write-Host '=== Resolve latest Flutter stable (tiered metadata) ===' -ForegroundColor Cyan
$release = Get-LatestFlutterStableRelease
Write-Host ('  stable ' + $release.version + ' (hash ' + $release.hash.Substring(0, 8) + '...)') -ForegroundColor Green

$installed = Get-InstalledFlutterVersion -FlutterRoot $FlutterRoot
$needsUpgrade = $Force -or (Test-NeedsVersionUpgrade -Installed $installed -Latest $release.version)

if (-not $needsUpgrade) {
    Write-Host ('Flutter ' + $installed + ' already current at ' + $FlutterRoot) -ForegroundColor Green
    exit 0
}

if ($installed) {
    Write-Host ('  upgrade: ' + $installed + ' -> ' + $release.version) -ForegroundColor Yellow
}

$zipName = Split-Path $release.archive -Leaf
$zipPath = Join-Path $env:TEMP $zipName
$zipTiers = Get-FlutterSdkZipUrls -Release $release

Write-Host ('=== Download Flutter ' + $release.version + ' ===') -ForegroundColor Cyan
$dl = Invoke-TieredDownload -Label 'Flutter SDK' `
    -PrimaryUrls $zipTiers.Primary `
    -FallbackUrls $zipTiers.Fallback `
    -IranUrls $zipTiers.Iran `
    -Dest $zipPath `
    -MinBytes 50MB `
    -MaxTimeSec 7200 `
    -Resume `
    -TryProxyOnFailure

if (-not $dl.success) {
    throw 'Flutter SDK download failed on all tiers (official -> fallback -> iran -> SOCKS)'
}
Write-Host ('  downloaded ' + [math]::Round((Get-Item $zipPath).Length / 1MB, 1) + ' MB via ' + $dl.tier) -ForegroundColor Green

if ($SkipExtract) {
    Write-Host ('SkipExtract - zip at ' + $zipPath)
    exit 0
}

$stageParent = Join-Path $env:TEMP ('flutter_extract_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$stageNew = Join-Path $stageParent 'flutter_new'
if (Test-Path $stageParent) { Remove-Item -Recurse -Force $stageParent }
New-Item -ItemType Directory -Force -Path $stageNew | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $stageNew -Force

$innerFlutter = Get-ChildItem $stageNew -Recurse -Directory -Filter 'flutter' -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'bin\flutter.bat') } |
    Select-Object -First 1
if (-not $innerFlutter) {
    if (Test-Path (Join-Path $stageNew 'bin\flutter.bat')) { $innerFlutter = Get-Item $stageNew }
    else { throw 'Unexpected Flutter ZIP layout' }
}

$oldRoot = $null
if (Test-Path $FlutterRoot) {
    $oldRoot = Join-Path $env:TEMP ('flutter_old_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    Write-Host ('  staging old SDK -> ' + $oldRoot) -ForegroundColor Yellow
    Move-Item $FlutterRoot $oldRoot -Force
}

New-Item -ItemType Directory -Force -Path (Split-Path $FlutterRoot -Parent) | Out-Null
Move-Item $innerFlutter.FullName $FlutterRoot -Force
Remove-Item -Recurse -Force $stageParent, $zipPath -ErrorAction SilentlyContinue
if ($oldRoot -and (Test-Path $oldRoot)) {
    Remove-OldToolchainDirectory -Path $oldRoot -Label 'Flutter SDK'
}

$stateDir = Join-Path $FlutterRoot '..' | Resolve-Path
$stateFile = Join-Path $stateDir '.flutter-sdk-version'
Set-Content -Path $stateFile -Value $release.version -Encoding UTF8 -NoNewline

Write-Host ('Flutter ' + $release.version + ' stable installed: ' + $FlutterRoot) -ForegroundColor Green
