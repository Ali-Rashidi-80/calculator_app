# Full D: drive toolchain install - JDK 17, Flutter stable (dynamic), Android SDK, env vars.
# Android 8.1+ (minSdk 27) supported via project config; compileSdk from latest stable Flutter.
#
# Usage (from calculator_app root):
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-full-toolchain-d-drive.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-full-toolchain-d-drive.ps1 -SkipFlutterDownload

param(
    [string]$DevRoot = 'D:\Dev',
    [string]$FlutterRoot = $null,
    [string]$AndroidSdkRoot = $null,
    [string]$JavaHome = $null,
    [ValidateSet('auto', 'iran', 'china', 'official')]
    [string]$PubMirror = 'iran',
    [switch]$SkipFlutterDownload,
    [switch]$SkipJdk,
    [switch]$SkipNdk,
    [switch]$InstallWindowsDesktop,
    [switch]$SkipWindowsDesktop,
    [switch]$VerifyFlutter
)

$ErrorActionPreference = 'Stop'
$ToolchainRoot = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\toolchain-config.ps1"

$script:ToolchainDevRoot = $DevRoot
$FlutterRoot     = if ($FlutterRoot)     { $FlutterRoot }     else { Join-Path $DevRoot 'flutter' }
$AndroidSdkRoot  = if ($AndroidSdkRoot)  { $AndroidSdkRoot }  else { Join-Path $DevRoot 'Android\Sdk' }
$JavaHome        = if ($JavaHome)        { $JavaHome }        else { Join-Path $DevRoot 'Java\jdk-17' }
$PubCache        = Join-Path $DevRoot '.pub-cache'
$GradleUserHome  = Join-Path $DevRoot '.gradle'
$AndroidUserHome = Join-Path $DevRoot '.android'

Ensure-DevDirectories -DevRoot $DevRoot

Write-Host ''
Write-Host "=== calculator_app - full toolchain on $DevRoot ===" -ForegroundColor Cyan
Write-Host "  Flutter:  $FlutterRoot"
Write-Host "  Android:  $AndroidSdkRoot"
Write-Host "  Java:     $JavaHome"
Write-Host "  minSdk:   $($script:MinAndroidApi) (Android 8.1+)"
Write-Host ''

if (-not $SkipJdk) {
    & "$PSScriptRoot\install-jdk17-temurin.ps1" -JavaHome $JavaHome
}

if (-not $SkipFlutterDownload) {
    & "$PSScriptRoot\install-flutter-sdk-stable.ps1" -FlutterRoot $FlutterRoot
}

$release = Get-LatestFlutterStableRelease
$androidReq = Get-FlutterAndroidRequirements -FlutterRoot $FlutterRoot
Write-Host "Flutter stable: $($release.version) | compileSdk: $($androidReq.CompileSdk) | build-tools: $($androidReq.BuildTools)" -ForegroundColor Green

& "$PSScriptRoot\install-flutter-mobile-toolchain-iran.ps1" `
    -FlutterRoot $FlutterRoot `
    -AndroidSdkRoot $AndroidSdkRoot `
    -JavaHome $JavaHome `
    -PubCache $PubCache `
    -GradleUserHome $GradleUserHome `
    -AndroidUserHome $AndroidUserHome `
    -PubMirror $PubMirror `
    -CompileSdk $androidReq.CompileSdk `
    -BuildToolsVersion $androidReq.BuildTools `
    -BuildToolsShimVersion $androidReq.BuildToolsShim `
    -NdkVersion $androidReq.NdkVersion `
    $(if ($VerifyFlutter) { '-VerifyFlutter' })

$ndkSwitch = if ($SkipNdk) { @() } else { @('-IncludeNdk') }
& "$PSScriptRoot\install-android-sdk-packages-iran.ps1" `
    -AndroidSdkRoot $AndroidSdkRoot `
    -FlutterRoot $FlutterRoot `
    @ndkSwitch

if ($InstallWindowsDesktop -or (-not $SkipWindowsDesktop)) {
    Write-Host ''
    Write-Host '=== Windows desktop toolchain (VS Build Tools) ===' -ForegroundColor Cyan
    & "$PSScriptRoot\install-windows-desktop-toolchain.ps1"
}

Write-Host ''
Write-Host '=== Verify ===' -ForegroundColor Cyan
& "$PSScriptRoot\verify-flutter-setup.ps1" `
    -FlutterRoot $FlutterRoot `
    -AndroidSdkRoot $AndroidSdkRoot `
    -JavaHome $JavaHome `
    -PubCache $PubCache `
    -GradleUserHome $GradleUserHome `
    -CompileSdk $androidReq.CompileSdk `
    -BuildToolsVersion $androidReq.BuildTools `
    -Strict `
    -SkipDoctor

Write-Host ''
Write-Host 'Done. Open a NEW PowerShell window, then:' -ForegroundColor Green
Write-Host '  cd D:\0\calculator_app\calculator_app'
Write-Host '  flutter pub get'
Write-Host '  flutter test'
Write-Host '  flutter build apk --release'
Write-Host ''
Write-Host 'Docs: toolchain/docs/FLUTTER-SETUP-FA.md' -ForegroundColor Green
