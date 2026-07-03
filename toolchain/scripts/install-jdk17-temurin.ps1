# Download Temurin JDK 17 LTS; auto-upgrade when newer stable on each run.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-jdk17-temurin.ps1

param(
    [string]$JavaHome = $null,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\toolchain-config.ps1"

if (-not $JavaHome) { $JavaHome = $script:DefaultJavaHome }
Ensure-DevDirectories

Write-Host '=== Resolve latest Temurin JDK 17 LTS (tiered API) ===' -ForegroundColor Cyan
$jdk = Get-LatestTemurinJdk17
Write-Host ('  remote: ' + $jdk.version) -ForegroundColor Green

$installed = Get-InstalledJdkVersion -JavaHome $JavaHome
$needsUpgrade = $Force -or (-not $installed)
if ($installed -and $jdk.version) {
    $remoteShort = ($jdk.version -replace '\+.*', '')
    if ($installed -ne $remoteShort) { $needsUpgrade = $true }
}

if (-not $needsUpgrade) {
    $verLine = cmd /c "`"$(Join-Path $JavaHome 'bin\java.exe')`" -version 2>&1" | Select-Object -First 1
    Write-Host ('JDK already current at ' + $JavaHome + ' - ' + $verLine) -ForegroundColor Green
    exit 0
}

if ($installed) { Write-Host ('  upgrade JDK: ' + $installed + ' -> ' + $jdk.version) -ForegroundColor Yellow }

$zipPath = Join-Path $env:TEMP ('temurin-jdk17-' + ($jdk.version -replace '[^\d]+', '_') + '.zip')
$urlTiers = Get-JdkDownloadUrls -JdkInfo $jdk

Write-Host '=== Download JDK 17 ===' -ForegroundColor Cyan
$dl = Invoke-TieredDownload -Label 'Temurin JDK 17' `
    -PrimaryUrls $urlTiers.Primary `
    -FallbackUrls $urlTiers.Fallback `
    -IranUrls $urlTiers.Iran `
    -Dest $zipPath `
    -MinBytes 50MB `
    -MaxTimeSec 1800 `
    -Resume `
    -TryProxyOnFailure

if (-not $dl.success) { throw 'JDK download failed on all tiers' }
Write-Host ('  downloaded ' + [math]::Round((Get-Item $zipPath).Length / 1MB, 1) + ' MB') -ForegroundColor Green

$stage = Join-Path $env:TEMP ('jdk_extract_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
Expand-Archive -Path $zipPath -DestinationPath $stage -Force
$inner = Get-ChildItem $stage -Directory | Select-Object -First 1
if (-not $inner -or -not (Test-Path (Join-Path $inner.FullName 'bin\java.exe'))) {
    throw 'Unexpected JDK ZIP layout'
}

$oldHome = $null
if (Test-Path $JavaHome) {
    $oldHome = Join-Path $env:TEMP ('jdk_old_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    Move-Item $JavaHome $oldHome -Force
}
New-Item -ItemType Directory -Force -Path (Split-Path $JavaHome -Parent) | Out-Null
Move-Item $inner.FullName $JavaHome -Force
Remove-Item -Recurse -Force $stage, $zipPath -ErrorAction SilentlyContinue
if ($oldHome) { Remove-OldToolchainDirectory -Path $oldHome -Label 'JDK' }

$verLine = cmd /c "`"$(Join-Path $JavaHome 'bin\java.exe')`" -version 2>&1" | Select-Object -First 1
Write-Host ('JDK installed: ' + $JavaHome + ' - ' + $verLine) -ForegroundColor Green
