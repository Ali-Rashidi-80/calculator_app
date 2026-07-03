# Atomic analysis + verification for Flutter/Dart toolchain (Iran network).
# Combines env/PATH/SDK checks with policy warnings and optional strict APK mode.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/verify-flutter-setup.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/verify-flutter-setup.ps1 -Strict
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/verify-flutter-setup.ps1 -SkipDoctor

param(
    [string]$FlutterRoot = $null,
    [string]$AndroidSdkRoot = $null,
    [string]$JavaHome = $null,
    [string]$PubCache = $null,
    [string]$GradleUserHome = $null,
    [string]$AndroidUserHome = $null,
    [int]$CompileSdk = 0,
    [string]$BuildToolsVersion = $null,
    [string]$BuildToolsShimVersion = $null,
    [string]$ToolchainRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Strict,
    [switch]$SkipDoctor
)

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\toolchain-config.ps1"

if (-not $FlutterRoot) { $FlutterRoot = $script:DefaultFlutterRoot }
if (-not $AndroidSdkRoot) { $AndroidSdkRoot = $script:DefaultAndroidSdkRoot }
if (-not $JavaHome) { $JavaHome = $script:DefaultJavaHome }
if (-not $PubCache) { $PubCache = $script:DefaultPubCache }
if (-not $GradleUserHome) { $GradleUserHome = $script:DefaultGradleUserHome }
if (-not $AndroidUserHome) { $AndroidUserHome = $script:DefaultAndroidUserHome }

$androidReq = Get-FlutterAndroidRequirements -FlutterRoot $FlutterRoot
if ($CompileSdk -le 0) { $CompileSdk = $androidReq.CompileSdk }
if (-not $BuildToolsVersion) { $BuildToolsVersion = $androidReq.BuildTools }
if (-not $BuildToolsShimVersion) { $BuildToolsShimVersion = $androidReq.BuildToolsShim }

$projectRoot = Split-Path -Parent $ToolchainRoot

$fail = 0
$warn = 0

function Check([bool]$Ok, [string]$Label, [string]$Detail = '', [switch]$WarningOnly) {
    if ($Ok) {
        Write-Host "[OK] $Label" -ForegroundColor Green
        if ($Detail) { Write-Host "     $Detail" }
        return
    }
    if ($WarningOnly) {
        Write-Host "[WARN] $Label" -ForegroundColor Yellow
        if ($Detail) { Write-Host "     $Detail" }
        $script:warn++
        return
    }
    Write-Host "[FAIL] $Label" -ForegroundColor Red
    if ($Detail) { Write-Host "     $Detail" }
    $script:fail++
}

Write-Host "`n=== Flutter toolchain verify ===" -ForegroundColor Cyan
Write-Host "Strict APK mode: $Strict | compileSdk: $CompileSdk | minSdk policy: $($script:MinAndroidApi) (Android 8.1+)"
Write-Host "Docs: toolchain/docs/README-FA.md`n"

Write-Host "=== Environment variables (User) ===" -ForegroundColor Cyan
$expected = @{
    ANDROID_HOME       = $AndroidSdkRoot
    ANDROID_SDK_ROOT   = $AndroidSdkRoot
    PUB_CACHE          = $PubCache
    GRADLE_USER_HOME   = $GradleUserHome
    ANDROID_USER_HOME  = $AndroidUserHome
    PUB_HOSTED_URL     = $null
    FLUTTER_STORAGE_BASE_URL = $null
    JAVA_HOME          = $JavaHome
}
foreach ($k in $expected.Keys) {
    $v = [Environment]::GetEnvironmentVariable($k, 'User')
    if ($expected[$k]) { Check ($v -eq $expected[$k]) "$k" $v }
    else { Check ([bool]$v) "$k" $v }
}
$fr = [Environment]::GetEnvironmentVariable('FLUTTER_ROOT', 'User')
Check ([bool]$fr) 'FLUTTER_ROOT' $fr

$pub = [Environment]::GetEnvironmentVariable('PUB_HOSTED_URL', 'User')
if ($pub -match 'pub-azs\.ir') {
    Check $false 'PUB_HOSTED_URL mirror quality' 'pub-azs.ir may fail content-hash — prefer https://pub.myket.ir' -WarningOnly
} elseif ($pub -match 'pub\.myket\.ir') {
    Check $true 'PUB_HOSTED_URL recommended mirror' $pub
}

Write-Host "`n=== PATH segments ===" -ForegroundColor Cyan
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
$required = @(
    (Join-Path $FlutterRoot 'bin'),
    (Join-Path $AndroidSdkRoot 'platform-tools'),
    (Join-Path $AndroidSdkRoot 'cmdline-tools\latest\bin')
)
foreach ($seg in $required) {
    Check ($userPath -contains $seg) "PATH contains $seg"
}

Write-Host "`n=== CLI tools ===" -ForegroundColor Cyan
Initialize-ToolchainSessionEnv -FlutterRoot $FlutterRoot -AndroidSdkRoot $AndroidSdkRoot -JavaHome $JavaHome -PubCache $PubCache -GradleUserHome $GradleUserHome
$jdkJava = Join-Path $JavaHome 'bin\java.exe'
$userPathParts = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
Check ($userPathParts -contains (Join-Path $JavaHome 'bin')) 'PATH contains JAVA_HOME\bin'
foreach ($cmd in @('flutter', 'dart', 'adb')) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    Check ([bool]$c) "$cmd in PATH" $(if ($c) { $c.Source })
}
if (Test-Path $jdkJava) {
    Check (Test-Path $jdkJava) 'JAVA_HOME java.exe'
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    $javaOk = $javaCmd -and ($javaCmd.Source -ieq $jdkJava)
    Check $javaOk 'java resolves to JAVA_HOME (not stale Oracle JRE)' $(if ($javaCmd) { $javaCmd.Source } else { 'java not in PATH' })
} else {
    Check $false 'JAVA_HOME java.exe exists' $JavaHome
}

Write-Host "`n=== Android SDK (atomic) ===" -ForegroundColor Cyan
Check (Test-Path "$AndroidSdkRoot\cmdline-tools\latest\bin\sdkmanager.bat") 'cmdline-tools'
Check (Test-Path "$AndroidSdkRoot\platform-tools\adb.exe") 'platform-tools'
Check (Test-Path "$AndroidSdkRoot\licenses") 'licenses directory'
Check (Test-Path "$AndroidSdkRoot\build-tools\$BuildToolsVersion\aapt.exe") "build-tools $BuildToolsVersion"
Check (Test-Path "$AndroidSdkRoot\build-tools\$BuildToolsShimVersion\aapt.exe") "build-tools $BuildToolsShimVersion (AGP label)"
Check (Test-Path "$AndroidSdkRoot\platforms\android-$CompileSdk\android.jar") "platform android-$CompileSdk"
Check (Test-Path "$AndroidSdkRoot\cmake\3.22.1\bin\cmake.exe") 'cmake 3.22.1'
$cmakeShare = Get-ChildItem "$AndroidSdkRoot\cmake\3.22.1\share" -Directory -Filter 'cmake-*' -ErrorAction SilentlyContinue | Select-Object -First 1
Check ([bool]$cmakeShare) 'cmake share/cmake-*'
$ndkDirs = @(Get-ChildItem "$AndroidSdkRoot\ndk" -Directory -ErrorAction SilentlyContinue)
if ($Strict) {
    Check ($ndkDirs.Count -gt 0) 'NDK side-by-side (required for release APK)' $(if ($ndkDirs) { ($ndkDirs.Name -join ', ') })
} else {
    Check ($ndkDirs.Count -gt 0) 'NDK side-by-side' $(if ($ndkDirs) { ($ndkDirs.Name -join ', ') }) -WarningOnly:$(-not $ndkDirs.Count)
}

Write-Host "`n=== Windows desktop (Flutter build windows) ===" -ForegroundColor Cyan
$winStatus = Test-WindowsDesktopToolchain -ExpectedPath $script:DefaultVsInstallPath
$vswhereExe = Get-VsWhereExe
Check ([bool]$vswhereExe -and (Test-Path $vswhereExe)) 'vswhere.exe (VS Installer)'
if ($Strict) {
    Check $winStatus.ready 'Visual Studio Build Tools (MSVC + CMake)' $(if ($winStatus.ready) { $winStatus.path } else { $winStatus.reason })
    Check ([bool]$winStatus.cmakeExe) 'CMake inside VS install' $winStatus.cmakeExe
} else {
    Check $winStatus.ready 'Visual Studio Build Tools' $(if ($winStatus.ready) { $winStatus.path } else { $winStatus.reason }) -WarningOnly:$(-not $winStatus.ready)
}
Check $winStatus.sdkOk 'Windows 10/11 SDK' -WarningOnly:$(-not $winStatus.sdkOk)
Check (Test-Path $script:DefaultVsInstallPath) "VS install path ($($script:DefaultVsInstallPath))" -WarningOnly:$(-not (Test-Path $script:DefaultVsInstallPath))

Write-Host "`n=== Gradle / mirrors ===" -ForegroundColor Cyan
Check (Test-Path "$GradleUserHome\gradle.properties") 'user gradle.properties (GRADLE_USER_HOME)'
$socksUp = Test-SocksProxyAvailable
$gradlePropsTxt = if (Test-Path "$GradleUserHome\gradle.properties") {
    Get-Content "$GradleUserHome\gradle.properties" -Raw
} else { '' }
$gradleHasSocks = $gradlePropsTxt -match 'socksProxyHost'
if ($gradleHasSocks -and -not $socksUp) {
    Check $false 'Gradle SOCKS proxy config' 'SOCKS in gradle.properties but 127.0.0.1:10808 is down — run patch-flutter-gradle-mirrors.ps1'
} elseif ($gradleHasSocks -and $socksUp) {
    Check $true 'Gradle SOCKS proxy (active)' '127.0.0.1:10808'
} else {
    Check $true 'Gradle direct/mirrors (no SOCKS)' 'mirrors only — OK when proxy is off'
}
$projGradleProps = Join-Path $projectRoot 'android\gradle.properties'
if (Test-Path $projGradleProps) {
    $pg = Get-Content $projGradleProps -Raw
    Check ($pg -notmatch 'socksProxyHost') 'android/gradle.properties has no hardcoded SOCKS'
}
Check (Test-Path "$GradleUserHome\wrapper\dists\gradle-8.14-all") 'Gradle 8.14 cached' -WarningOnly
$initDeprecated = Join-Path $GradleUserHome 'init.d\flutter-iran-mirrors.gradle'
Check (-not (Test-Path $initDeprecated)) 'no deprecated init.d/flutter-iran-mirrors.gradle' $(if (Test-Path $initDeprecated) { 'Remove — breaks Flutter 3.38' })
$flutterGradle = Join-Path $FlutterRoot 'packages\flutter_tools\gradle\settings.gradle.kts'
if (Test-Path $flutterGradle) {
    $txt = Get-Content $flutterGradle -Raw
    Check ($txt -match 'maven\.myket\.ir') 'Flutter SDK Gradle mirrors patched' $flutterGradle
    $openBr = ([regex]::Matches($txt, '\{')).Count
    $closeBr = ([regex]::Matches($txt, '\}')).Count
    Check ($openBr -eq $closeBr) 'Flutter settings.gradle.kts balanced braces' "open=$openBr close=$closeBr"
}

Write-Host "`n=== Toolchain scripts (parse) ===" -ForegroundColor Cyan
$scriptNames = @(
    'download-resolver.ps1',
    'toolchain-config.ps1',
    'install-flutter-sdk-stable.ps1',
    'install-jdk17-temurin.ps1',
    'install-full-toolchain-d-drive.ps1',
    'install-flutter-mobile-toolchain-iran.ps1',
    'install-android-sdk-packages-iran.ps1',
    'install-windows-desktop-toolchain.ps1',
    'patch-flutter-gradle-mirrors.ps1',
    'probe-flutter-mirrors-iran.ps1',
    'verify-flutter-setup.ps1',
    'run-production-builds.ps1'
)
$scriptsDir = Join-Path $ToolchainRoot 'scripts'
foreach ($name in $scriptNames) {
    $path = Join-Path $scriptsDir $name
    if (-not (Test-Path $path)) {
        Check $false "script exists: $name"
        continue
    }
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$parseErrors)
    Check ($null -eq $parseErrors -or $parseErrors.Count -eq 0) "parse OK: $name" $(if ($parseErrors) { $parseErrors[0].Message })
}

Write-Host "`n=== Toolchain templates ===" -ForegroundColor Cyan
$templateNames = @(
    'flutter-android-mirrors.snippet.kts',
    'gradle-user.properties',
    'android-repositories.cfg'
)
$templatesDir = Join-Path $ToolchainRoot 'templates'
foreach ($name in $templateNames) {
    Check (Test-Path (Join-Path $templatesDir $name)) "template: $name"
}

Write-Host "`n=== Documentation ===" -ForegroundColor Cyan
$docsDir = Join-Path $ToolchainRoot 'docs'
$docNames = @(
    'README-FA.md',
    'GUIDE-WEB-FA.md',
    'GUIDE-WINDOWS-FA.md',
    'GUIDE-MOBILE-FA.md',
    'FLUTTER-SETUP-FA.md'
)
foreach ($name in $docNames) {
    Check (Test-Path (Join-Path $docsDir $name)) "doc: $name"
}

Write-Host "`n=== Project (calculator_app) ===" -ForegroundColor Cyan
Check (Test-Path (Join-Path $projectRoot 'README.md')) 'root README.md'
Check (Test-Path (Join-Path $projectRoot 'lib\main.dart')) 'lib/main.dart'
Check (Test-Path (Join-Path $projectRoot 'lib\calculator.dart')) 'lib/calculator.dart'
Check (Test-Path (Join-Path $projectRoot 'pubspec.yaml')) 'pubspec.yaml'

$appGradle = Join-Path $projectRoot 'android\app\build.gradle.kts'
if (Test-Path $appGradle) {
    $gradleTxt = Get-Content $appGradle -Raw
    Check ($gradleTxt -match 'minSdk\s*=\s*27') "minSdk 27 (Android 8.1+) in android/app/build.gradle.kts"
} else {
    Check $false 'android/app/build.gradle.kts exists'
}

$settingsGradle = Join-Path $projectRoot 'android\settings.gradle.kts'
if (Test-Path $settingsGradle) {
    $setTxt = Get-Content $settingsGradle -Raw
    Check ($setTxt -match 'maven\.myket\.ir') 'Gradle mirrors in android/settings.gradle.kts'
}

if (-not $SkipDoctor) {
    Write-Host "`n=== flutter doctor ===" -ForegroundColor Cyan
    $flutter = Join-Path $FlutterRoot 'bin\flutter.bat'
    if (Test-Path $flutter) { & $flutter doctor 2>&1 }
    else { Check $false 'flutter.bat exists' }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($fail -eq 0 -and $warn -eq 0) {
    Write-Host "All checks passed. Toolchain ready (Android $($script:MinAndroidApi)+ / 8.1 Oreo through latest, Windows/Web)." -ForegroundColor Green
} elseif ($fail -eq 0) {
    Write-Host "Passed with $warn warning(s). See toolchain/docs/README-FA.md" -ForegroundColor Yellow
} else {
    Write-Host "$fail failure(s), $warn warning(s). See toolchain/docs/README-FA.md" -ForegroundColor Yellow
}
exit $fail
