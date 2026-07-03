# Android SDK packages via tiered download (official -> regional -> iran).
# Resolves versions from installed Flutter stable; re-run safe (skips present packages).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-android-sdk-packages-iran.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-android-sdk-packages-iran.ps1 -IncludeNdk

param(
    [string]$AndroidSdkRoot = $null,
    [string]$FlutterRoot = $null,
    [switch]$IncludeNdk,
    [switch]$SkipBuildTools,
    [switch]$SkipPlatform,
    [switch]$ForceRefresh
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\toolchain-config.ps1"

if (-not $AndroidSdkRoot) { $AndroidSdkRoot = $script:DefaultAndroidSdkRoot }
if (-not $FlutterRoot) { $FlutterRoot = $script:DefaultFlutterRoot }

$req = Get-FlutterAndroidRequirements -FlutterRoot $FlutterRoot
$CompileSdk = $req.CompileSdk
$BuildToolsVersion = $req.BuildTools
$BuildToolsShimVersion = $req.BuildToolsShim
$NdkVersion = $req.NdkVersion
$CmakeVersion = $req.CmakeVersion

Write-Host "Android SDK (tiered): compileSdk=$CompileSdk build-tools=$BuildToolsVersion ndk=$NdkVersion" -ForegroundColor Cyan

function Install-ZipPackageTiered {
    param(
        [string]$ZipLeaf,
        [string]$FinalDir,
        [string]$VerifyRelativePath,
        [long]$MinBytes = 500KB,
        [int]$MaxTimeSec = 900
    )
    $verify = Join-Path $FinalDir $VerifyRelativePath
    if ((Test-Path $verify) -and -not $ForceRefresh) {
        Write-Host "  skip (installed): $FinalDir" -ForegroundColor DarkGray
        return
    }
    if ($ForceRefresh -and (Test-Path $FinalDir)) { Remove-Item $FinalDir -Recurse -Force }
    $zip = Join-Path $env:TEMP $ZipLeaf
    $tiers = Get-AndroidSdkZipUrls -ZipLeaf $ZipLeaf
    $dl = Invoke-TieredDownload -Label $ZipLeaf `
        -PrimaryUrls $tiers.Primary -FallbackUrls $tiers.Fallback -IranUrls $tiers.Iran `
        -Dest $zip -MinBytes $MinBytes -MaxTimeSec $MaxTimeSec -Resume -TryProxyOnFailure
    if (-not $dl.success) { throw "Download failed: $ZipLeaf" }

    $stage = Join-Path $env:TEMP ('pkg_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Expand-Archive -Force $zip -DestinationPath $stage
    $inner = Get-ChildItem $stage -Directory | Select-Object -First 1
    if (-not $inner) { throw "Bad zip layout: $ZipLeaf" }
    if (Test-Path $FinalDir) { Remove-Item $FinalDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path (Split-Path $FinalDir -Parent) | Out-Null
    Move-Item $inner.FullName $FinalDir
    if (-not (Test-Path $verify)) {
        $nested = Get-ChildItem $FinalDir -Directory | Where-Object { $_.Name -like 'android-*' } | Select-Object -First 1
        if ($nested) {
            Get-ChildItem $nested.FullName | Move-Item -Destination $FinalDir -Force
            Remove-Item $nested.FullName -Recurse -Force
        }
    }
    Remove-Item $stage, $zip -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  -> $FinalDir" -ForegroundColor Green
}

New-Item -ItemType Directory -Force -Path $AndroidSdkRoot | Out-Null

if (-not $SkipBuildTools) {
    Install-ZipPackageTiered -ZipLeaf $req.BuildToolsZip `
        -FinalDir "$AndroidSdkRoot\build-tools\$BuildToolsVersion" `
        -VerifyRelativePath 'aapt.exe'
    $btShim = "$AndroidSdkRoot\build-tools\$BuildToolsShimVersion"
    if (-not (Test-Path "$btShim\aapt.exe")) {
        Copy-Item "$AndroidSdkRoot\build-tools\$BuildToolsVersion" $btShim -Recurse -Force
        (Get-Content "$btShim\source.properties") -replace [regex]::Escape($BuildToolsVersion), $BuildToolsShimVersion | Set-Content "$btShim\source.properties"
        $major = ($BuildToolsShimVersion -split '\.')[0]
        @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:repository xmlns:ns2="http://schemas.android.com/repository/android/common/02" xmlns:ns5="http://schemas.android.com/repository/android/generic/02"><license id="license-280F93AC" type="text"/><localPackage path="build-tools;$BuildToolsShimVersion" obsolete="false"><type-details xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns5:genericDetailsType"/><revision><major>$major</major><minor>0</minor><micro>0</micro></revision><display-name>Android SDK Build-Tools $major</display-name><uses-license ref="license-280F93AC"/></localPackage></ns2:repository>
"@ | Set-Content "$btShim\package.xml" -Encoding UTF8
        Write-Host "  build-tools $BuildToolsShimVersion (shim)" -ForegroundColor Yellow
    }
}

$cmakeLeaf = "cmake-$CmakeVersion-windows.zip"
Install-ZipPackageTiered -ZipLeaf $cmakeLeaf `
    -FinalDir "$AndroidSdkRoot\cmake\$CmakeVersion" `
    -VerifyRelativePath 'bin\cmake.exe'
$cmakeDest = "$AndroidSdkRoot\cmake\$CmakeVersion"
if (Test-Path "$cmakeDest\cmake.exe") {
    New-Item -ItemType Directory -Force -Path "$cmakeDest\bin" | Out-Null
    @('cmake.exe', 'cpack.exe', 'ctest.exe', 'cmcldeps.exe', 'ninja.exe') | ForEach-Object {
        if (Test-Path "$cmakeDest\$_") { Move-Item "$cmakeDest\$_" "$cmakeDest\bin\$_" -Force }
    }
}

if (-not $SkipPlatform) {
    Install-ZipPackageTiered -ZipLeaf $req.PlatformZip `
        -FinalDir "$AndroidSdkRoot\platforms\android-$CompileSdk" `
        -VerifyRelativePath 'android.jar'
}

if ($IncludeNdk) {
    $ndkDest = "$AndroidSdkRoot\ndk\$NdkVersion"
    if ((Test-Path "$ndkDest\ndk-build.cmd") -and -not $ForceRefresh) {
        Write-Host "NDK $NdkVersion already installed" -ForegroundColor Green
    } else {
        $zip = Join-Path $env:TEMP $req.NdkZip
        $tiers = Get-AndroidSdkZipUrls -ZipLeaf $req.NdkZip
        $dl = Invoke-TieredDownload -Label 'Android NDK' `
            -PrimaryUrls $tiers.Primary -FallbackUrls $tiers.Fallback -IranUrls $tiers.Iran `
            -Dest $zip -MinBytes 700MB -MaxTimeSec 7200 -Resume -TryProxyOnFailure
        if (-not $dl.success) { throw 'NDK download failed on all tiers' }
        $stage = Join-Path $env:TEMP 'ndk_stage'
        if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
        Expand-Archive -Force $zip -DestinationPath $stage
        $inner = Get-ChildItem $stage -Directory | Select-Object -First 1
        if (Test-Path $ndkDest) { Remove-Item $ndkDest -Recurse -Force }
        New-Item -ItemType Directory -Force -Path "$AndroidSdkRoot\ndk" | Out-Null
        Move-Item $inner.FullName $ndkDest
        Remove-Item $stage, $zip -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  -> $ndkDest" -ForegroundColor Green
    }
}

Write-Host "`nAndroid SDK packages OK (compileSdk=$CompileSdk, minSdk $($script:MinAndroidApi)+)." -ForegroundColor Green
