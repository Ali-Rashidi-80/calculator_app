# Patch Flutter SDK Gradle settings for Maven mirrors (required for AGP download in Iran).
# Safe to re-run (idempotent).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/patch-flutter-gradle-mirrors.ps1

param(
    [string]$FlutterRoot = $null,
    [string]$GradleUserHome = $null
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\toolchain-config.ps1"
if (-not $FlutterRoot) { $FlutterRoot = $script:DefaultFlutterRoot }
if (-not $GradleUserHome) { $GradleUserHome = $script:DefaultGradleUserHome }
New-Item -ItemType Directory -Force -Path $GradleUserHome | Out-Null
$env:GRADLE_USER_HOME = $GradleUserHome
$settingsFile = Join-Path $FlutterRoot 'packages\flutter_tools\gradle\settings.gradle.kts'
if (-not (Test-Path $settingsFile)) {
    throw "Not found: $settingsFile"
}

$desired = @'
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        maven { url = uri("https://maven.myket.ir") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
    }
}
'@

$content = Get-Content $settingsFile -Raw
if ($content -match 'maven\.myket\.ir') {
    Write-Host "Flutter Gradle mirrors already patched." -ForegroundColor Green
} else {
    if ($content -notmatch 'dependencyResolutionManagement') {
        throw "Unexpected settings.gradle.kts format - update patch script."
    }
    $content = $content -replace '(?s)dependencyResolutionManagement\s*\{.*?\}\s*', ($desired.TrimEnd() + "`n")
    if ($content -match '(?s)dependencyResolutionManagement.*?\}\s*\}') {
        $content = $content -replace '(?s)(dependencyResolutionManagement\s*\{.*?\})\s*\}', '$1'
    }
    Set-Content -Path $settingsFile -Value $content.TrimEnd() -Encoding UTF8 -NoNewline
    Write-Host "Patched: $settingsFile" -ForegroundColor Green
}

# User Gradle: disable broken system proxy; SOCKS only when proxy is actually listening
$gradleResult = Write-GradleUserProperties -GradleUserHome $GradleUserHome
if ($gradleResult.socks) {
    Write-Host "Gradle user properties (SOCKS active) -> $($gradleResult.path)" -ForegroundColor Green
} else {
    Write-Host "Gradle user properties (direct / mirrors, no SOCKS) -> $($gradleResult.path)" -ForegroundColor Green
}

# Remove deprecated init script (breaks Flutter 3.38 PREFER_SETTINGS)
$initScript = Join-Path $GradleUserHome 'init.d\flutter-iran-mirrors.gradle'
if (Test-Path $initScript) {
    Remove-Item $initScript -Force
    Write-Host "Removed deprecated init script (use settings.gradle.kts mirrors per project)." -ForegroundColor Yellow
}

Write-Host "Done. Add pluginManagement mirrors per project: toolchain/templates/flutter-android-mirrors.snippet.kts" -ForegroundColor Green
