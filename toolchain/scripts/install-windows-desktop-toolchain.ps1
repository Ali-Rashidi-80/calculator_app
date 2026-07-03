# Install Visual Studio 2022 Build Tools for flutter build windows (MSVC, CMake, Windows SDK).
# Tiered download: aka.ms / Microsoft -> SOCKS fallback. Install path default D:\Dev\VS2022BuildTools.
#
# Usage (Admin PowerShell recommended):
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-windows-desktop-toolchain.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-windows-desktop-toolchain.ps1 -Force

param(
    [string]$InstallPath = $null,
    [string]$CmakeRoot = $null,
    [switch]$Force,
    [switch]$SkipStandaloneCmake
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\toolchain-config.ps1"

if (-not $InstallPath) { $InstallPath = $script:DefaultVsInstallPath }
if (-not $CmakeRoot) { $CmakeRoot = $script:DefaultCmakeWinRoot }
Ensure-DevDirectories -Extra @($CmakeRoot)
New-Item -ItemType Directory -Force -Path (Split-Path $InstallPath -Parent) | Out-Null

$status = Test-WindowsDesktopToolchain -ExpectedPath $InstallPath
if ($status.ready -and -not $Force) {
    Write-Host ('Windows desktop toolchain OK: ' + $status.path) -ForegroundColor Green
    if (-not $status.sdkOk) { Write-Host '  Windows SDK registry entry thin - VS may still work' -ForegroundColor Yellow }
} else {
    Write-Host '=== Visual Studio 2022 Build Tools (Flutter Windows) ===' -ForegroundColor Cyan
    Write-Host "  install path: $InstallPath"
    Write-Host '  components: MSVC x64/x86, CMake, Windows 11 SDK 22621'

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host '  NOTE: Administrator rights recommended for VS install' -ForegroundColor Yellow
    }

    $setup = Get-VsInstallerExe
    $vswhere = Get-VsWhereExe
    $components = Get-FlutterRequiredVsComponents
    $addArgs = @()
    foreach ($c in $components) { $addArgs += '--add'; $addArgs += $c }

    $existingPath = $null
    $vswhere = Get-VsWhereExe
    if ($vswhere) {
        $existingPath = & $vswhere -latest -products * -property installationPath -format value 2>$null | Select-Object -First 1
    }
    $hasRealInstall = $existingPath -and (Test-Path (Join-Path $existingPath 'VC\Tools\MSVC'))

    if ($setup -and $hasRealInstall) {
        if ($existingPath -ne $InstallPath) {
            Write-Host "  using existing VS at $existingPath" -ForegroundColor Yellow
            $InstallPath = $existingPath
        }
        Write-Host '  modifying existing VS installation...' -ForegroundColor Cyan
        $procArgs = @(
            'modify', '--installPath', $InstallPath,
            '--includeRecommended', '--quiet', '--wait', '--norestart'
        ) + $addArgs
        $p = Start-Process -FilePath $setup -ArgumentList $procArgs -Wait -PassThru
        if ($p.ExitCode -gt 0) { throw "VS modify failed exit $($p.ExitCode)" }
    } else {
        if ((Test-Path $InstallPath) -and -not $hasRealInstall) {
            Remove-Item $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        $boot = Join-Path $env:TEMP 'vs_BuildTools.exe'
        $tiers = Get-VsBuildToolsBootstrapperUrls
        $dl = Invoke-TieredDownload -Label 'VS Build Tools bootstrapper' `
            -PrimaryUrls $tiers.Primary -FallbackUrls $tiers.Fallback -IranUrls $tiers.Iran `
            -Dest $boot -MinBytes 1MB -MaxTimeSec 1800 -Resume -TryProxyOnFailure
        if (-not $dl.success) { throw 'VS Build Tools bootstrapper download failed on all tiers' }

        Write-Host '  running VS installer (10-40 min, one-time)...' -ForegroundColor Cyan
        $procArgs = @(
            '--installPath', $InstallPath,
            '--includeRecommended', '--quiet', '--wait', '--norestart'
        ) + $addArgs
        $p = Start-Process -FilePath $boot -ArgumentList $procArgs -Wait -PassThru
        if ($p.ExitCode -gt 0) { throw "VS install failed exit $($p.ExitCode). Try Admin PowerShell." }
        Remove-Item -Force $boot -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }

    $status = $null
    foreach ($attempt in 1..6) {
        $status = Test-WindowsDesktopToolchain -ExpectedPath $InstallPath
        if ($status.ready) { break }
        if ($attempt -lt 6) { Start-Sleep -Seconds 10 }
    }
    if (-not $status.ready) { throw 'VS installed but Flutter requirements not satisfied - re-run with -Force' }
    Write-Host ('  VS ready: ' + $status.path) -ForegroundColor Green
}

if (-not $SkipStandaloneCmake) {
    $vsCmake = $null
    if ($status.path) {
        $candidate = Get-ChildItem -Path $status.path -Recurse -Filter 'cmake.exe' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match 'CMake\\bin\\cmake\.exe$' } | Select-Object -First 1
        if ($candidate) { $vsCmake = $candidate.FullName }
    }
    if ($vsCmake) {
        Write-Host ('CMake from VS: ' + $vsCmake) -ForegroundColor Green
    } else {
        Write-Host '=== Standalone CMake (tiered fallback) ===' -ForegroundColor Cyan
        $cmakeVer = '3.31.6'
        $cmakeBin = Join-Path $CmakeRoot "cmake-$cmakeVer-windows-x86_64\bin\cmake.exe"
        if ((Test-Path $cmakeBin) -and -not $Force) {
            Write-Host "CMake already at $cmakeBin" -ForegroundColor Green
        } else {
            $zipLeaf = "cmake-$cmakeVer-windows-x86_64.zip"
            $zip = Join-Path $env:TEMP $zipLeaf
            $tiers = Get-CmakeStandaloneWindowsUrls -Version $cmakeVer
            $dl = Invoke-TieredDownload -Label 'CMake Windows' `
                -PrimaryUrls $tiers.Primary -FallbackUrls $tiers.Fallback -IranUrls $tiers.Iran `
                -Dest $zip -MinBytes 5MB -MaxTimeSec 1200 -Resume -TryProxyOnFailure
            if (-not $dl.success) { throw 'CMake standalone download failed' }
            if (Test-Path $CmakeRoot) { Remove-Item $CmakeRoot -Recurse -Force }
            Expand-Archive -Force $zip -DestinationPath $CmakeRoot
            Remove-Item -Force $zip -ErrorAction SilentlyContinue
            Write-Host "CMake -> $cmakeBin" -ForegroundColor Green
        }
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $cmakeSeg = Join-Path $CmakeRoot "cmake-$cmakeVer-windows-x86_64\bin"
        if ($userPath -notlike "*$cmakeSeg*") {
            [Environment]::SetEnvironmentVariable('Path', "$cmakeSeg;$userPath", 'User')
        }
    }
}

$stateFile = Join-Path (Split-Path $InstallPath -Parent) '.vs-buildtools-state.txt'
@(
    "installPath=$InstallPath"
    "checked=$(Get-Date -Format o)"
    "flutterComponents=$(Get-FlutterRequiredVsComponents -join ',')"
) | Set-Content $stateFile -Encoding UTF8

Write-Host 'Windows desktop toolchain install complete.' -ForegroundColor Green
