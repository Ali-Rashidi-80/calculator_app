# Fast Flutter mobile toolchain install - no hang on flutter --version.
# Standalone toolchain for calculator_app.
#
# Fast path (default):
#   1. Set PUB_HOSTED_URL / FLUTTER_STORAGE (Iran mirrors, 3s probe)
#   2. Copy Gradle + sdkmanager mirror configs
#   3. curl-download Android cmdline-tools + platform-tools zips (parallel)
#   4. Optional sdkmanager packages (with timeout, skippable)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-flutter-mobile-toolchain-iran.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-flutter-mobile-toolchain-iran.ps1 -PubMirror iran
#   powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-flutter-mobile-toolchain-iran.ps1 -VerifyFlutter

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
    [string]$NdkVersion = $null,
    [ValidateSet('auto', 'iran', 'china', 'official')]
    [string]$PubMirror = 'auto',
    [switch]$SkipAndroidSdk,
    [switch]$SkipEnvPersist,
    [switch]$UseSdkManagerPackages,
    [switch]$VerifyFlutter,
    [int]$SdkManagerTimeoutSec = 90,
    [int]$FlutterVerifyTimeoutSec = 60
)

$ErrorActionPreference = 'Stop'
$ToolchainRoot = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\toolchain-config.ps1"

if (-not $FlutterRoot)     { $FlutterRoot = $script:DefaultFlutterRoot }
if (-not $AndroidSdkRoot)  { $AndroidSdkRoot = $script:DefaultAndroidSdkRoot }
if (-not $JavaHome)        { $JavaHome = $script:DefaultJavaHome }
if (-not $PubCache)        { $PubCache = $script:DefaultPubCache }
if (-not $GradleUserHome)  { $GradleUserHome = $script:DefaultGradleUserHome }
if (-not $AndroidUserHome) { $AndroidUserHome = $script:DefaultAndroidUserHome }

$androidReq = Get-FlutterAndroidRequirements -FlutterRoot $FlutterRoot
if ($CompileSdk -le 0) { $CompileSdk = $androidReq.CompileSdk }
if (-not $BuildToolsVersion) { $BuildToolsVersion = $androidReq.BuildTools }
if (-not $BuildToolsShimVersion) { $BuildToolsShimVersion = $androidReq.BuildToolsShim }
if (-not $NdkVersion) { $NdkVersion = $androidReq.NdkVersion }

$cmdlineZipTiers = Get-AndroidCmdlineToolsZipTiers -Revision $androidReq.CmdlineToolsRev
$platformToolsZipTiers = Get-AndroidPlatformToolsZipTiers

$sdkManagerPackages = @(
    "platforms;android-$CompileSdk",
    "build-tools;$BuildToolsVersion",
    "ndk;$NdkVersion"
)

$pubIran = @(
    @{ id = 'pub-myket'; pub = 'https://pub.myket.ir' }
    @{ id = 'pub-azs';   pub = 'https://pub-azs.ir' }
)
$pubFallback = @(
    @{ id = 'china-cfug'; pub = 'https://pub.flutter-io.cn'; storage = 'https://storage.flutter-io.cn' }
    @{ id = 'china-tuna'; pub = 'https://mirrors.tuna.tsinghua.edu.cn/dart-pub'; storage = 'https://storage.flutter-io.cn' }
)
$storageDefault = 'https://storage.flutter-io.cn'

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Select-PubMirrorFast([string]$Mode) {
    return Select-PubStorageMirrors -Mode $Mode
}

function Set-UserEnv([string]$Name, [string]$Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item -Path "Env:$Name" -Value $Value
}

function Add-UserPath([string]$Segment) {
    if (-not $Segment) { return }
    if ($Segment -match 'Git\\cmd' -and -not (Test-Path $Segment)) { return }
    if ($Segment -notmatch 'System32' -and -not (Test-Path $Segment)) { return }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -split ';' | Where-Object { $_ -ieq $Segment }) { return }
    [Environment]::SetEnvironmentVariable('Path', $(if ($userPath) { "$userPath;$Segment" } else { $Segment }), 'User')
    $env:Path = "$env:Path;$Segment"
}

# Ensure where.exe (System32) and git for flutter pub get
foreach ($seg in @('C:\Windows\System32', 'C:\Program Files\Git\cmd')) { Add-UserPath $seg }

# Remember Iran mirror base for platform-tools fallback
$script:LastWorkingMirrorBase = $null

function Invoke-FastDownload {
    param(
        [hashtable]$UrlTiers,
        [string]$Dest,
        [string]$Label
    )
    $dl = Invoke-TieredDownload -Label $Label `
        -PrimaryUrls $UrlTiers.Primary `
        -FallbackUrls $UrlTiers.Fallback `
        -IranUrls $UrlTiers.Iran `
        -Dest $Dest -MinBytes 100KB -MaxTimeSec 1800 -Resume -TryProxyOnFailure
    if ($dl.success -and $Label -eq 'cmdline-tools' -and $dl.url -match '^(https://[^/]+/android)/') {
        $script:LastWorkingMirrorBase = $Matches[1]
    }
    return $dl.success
}

function Expand-ZipTo([string]$ZipPath, [string]$DestDir) {
    if (Test-Path $DestDir) { Remove-Item -Recurse -Force $DestDir -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force
}

function Install-GradleMirrors {
    $patch = Join-Path $ToolchainRoot 'scripts\patch-flutter-gradle-mirrors.ps1'
    if (Test-Path $patch) {
        & $patch -FlutterRoot $FlutterRoot -GradleUserHome $GradleUserHome
    } else {
        Write-Host "patch-flutter-gradle-mirrors.ps1 not found" -ForegroundColor Yellow
    }
}

function Install-AndroidRepositoriesCfg {
    New-Item -ItemType Directory -Force -Path $AndroidUserHome | Out-Null
    Copy-Item -Force (Join-Path $ToolchainRoot 'templates\android-repositories.cfg') `
        (Join-Path $AndroidUserHome 'repositories.cfg')
}

function Write-AndroidLicenses([string]$SdkRoot) {
    $licDir = Join-Path $SdkRoot 'licenses'
    New-Item -ItemType Directory -Force -Path $licDir | Out-Null
    @(
        '24333f8a63b6825ea9c5514f83c2829b004d1fee',
        '84831b9409646a918e30573bab4c9c91346d8abd',
        'd975f751698a77b662f1254ddbeac390f6965f5',
        '33b6a2b64607f11b759f220eecca260290965ead',
        '8403addf88ab4874007e1c1b80d6c47f817eaabe',
        '1b3f6f480cf6636f4fb5f41eee093ee0'
    ) | ForEach-Object {
        $f = Join-Path $licDir $_
        if (-not (Test-Path $f)) { Set-Content -Path $f -Value $_ -NoNewline }
    }
    Write-Host "Android licenses -> $licDir" -ForegroundColor Green
}

function Install-CmdlineToolsZip([string]$SdkRoot) {
    $latestDir = Join-Path $SdkRoot 'cmdline-tools\latest'
    if (Test-Path (Join-Path $latestDir 'bin\sdkmanager.bat')) {
        Write-Host "cmdline-tools already installed" -ForegroundColor Green
        return
    }
    $zip = Join-Path $env:TEMP 'flutter-iran-cmdline-tools.zip'
    if (-not (Invoke-FastDownload -UrlTiers $cmdlineZipTiers -Dest $zip -Label 'cmdline-tools')) {
        Write-Host "cmdline-tools: all mirrors failed. Install via Android Studio -> SDK Manager -> Command-line Tools." -ForegroundColor Yellow
        return
    }
    $extract = Join-Path $env:TEMP 'flutter-iran-cmdline-extract'
    Expand-ZipTo $zip $extract
    New-Item -ItemType Directory -Force -Path $latestDir | Out-Null
    $inner = Get-ChildItem $extract -Recurse -Directory -Filter 'cmdline-tools' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($inner) {
        Copy-Item "$($inner.FullName)\*" $latestDir -Recurse -Force
    } else {
        Copy-Item "$extract\*" $latestDir -Recurse -Force
    }
    Remove-Item -Recurse -Force $extract, $zip -ErrorAction SilentlyContinue
    Write-Host "cmdline-tools -> $latestDir" -ForegroundColor Green
}

function Install-PlatformToolsZip([string]$SdkRoot) {
    $adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
    if (Test-Path $adb) {
        Write-Host "platform-tools already installed" -ForegroundColor Green
        return $true
    }
    $zip = Join-Path $env:TEMP 'flutter-iran-platform-tools.zip'
    if (-not (Invoke-FastDownload -UrlTiers $platformToolsZipTiers -Dest $zip -Label 'platform-tools')) {
        Write-Host "platform-tools zip unavailable on mirrors; will try sdkmanager..." -ForegroundColor Yellow
        return $false
    }
    $extract = Join-Path $env:TEMP 'flutter-iran-platform-extract'
    Expand-ZipTo $zip $extract
    $ptSrc = Join-Path $extract 'platform-tools'
    if (-not (Test-Path $ptSrc)) {
        $ptSrc = $extract
    }
    $ptDest = Join-Path $SdkRoot 'platform-tools'
    if (Test-Path $ptDest) { Remove-Item -Recurse -Force $ptDest }
    Move-Item $ptSrc $ptDest -Force
    Remove-Item -Recurse -Force $extract, $zip -ErrorAction SilentlyContinue
    Write-Host "platform-tools -> $ptDest" -ForegroundColor Green
    return $true
}

function Invoke-SdkManagerWithTimeout {
    param(
        [string]$SdkManager,
        [string]$SdkRoot,
        [string[]]$Packages,
        [int]$TimeoutSec
    )
    foreach ($pkg in $Packages) {
        Write-Host "  sdkmanager -> $pkg (max ${TimeoutSec}s)"
        try {
            $job = Start-Job -ScriptBlock {
                param($sm, $root, $p)
                & $sm --sdk_root=$root $p 2>&1
            } -ArgumentList $SdkManager, $SdkRoot, $pkg
            $done = Wait-Job $job -Timeout $TimeoutSec
            if (-not $done) {
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -Force -ErrorAction SilentlyContinue
                Write-Host "  TIMEOUT: $pkg - skip (install via Android Studio SDK Manager)" -ForegroundColor Yellow
                continue
            }
            Receive-Job $job -ErrorAction SilentlyContinue | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" }
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "  sdkmanager error for $pkg : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Invoke-FlutterVerify {
    param([string]$FlutterBin, [int]$TimeoutSec, [hashtable]$Mirror)
    $env:PUB_HOSTED_URL = $Mirror.pub
    $env:FLUTTER_STORAGE_BASE_URL = $Mirror.storage
    Write-Host "flutter --version (max ${TimeoutSec}s, mirrors set)..."
    $job = Start-Job -ScriptBlock {
        param($bin)
        & (Join-Path $bin 'flutter.bat') --version 2>&1
    } -ArgumentList $FlutterBin
    $done = Wait-Job $job -Timeout $TimeoutSec
    if (-not $done) {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Write-Host "flutter --version timed out (normal on first run). Open NEW terminal and run: flutter doctor" -ForegroundColor Yellow
        return
    }
    Receive-Job $job -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
    Remove-Job $job -Force -ErrorAction SilentlyContinue
}

# --- main ---
$sw = [Diagnostics.Stopwatch]::StartNew()
Write-Step "Flutter mobile toolchain - FAST install"
Write-Host "Toolchain root: $ToolchainRoot"
Write-Host "Dev layout: Flutter=$FlutterRoot | Android=$AndroidSdkRoot | compileSdk=$CompileSdk"

# 1. Mirrors (3s probe max)
Write-Step "Pub mirrors"
$selected = Select-PubMirrorFast -Mode $PubMirror
Write-Host "  $($selected.id) -> $($selected.pub)" -ForegroundColor Green
Write-Host "  storage -> $($selected.storage)"
$env:PUB_HOSTED_URL = $selected.pub
$env:FLUTTER_STORAGE_BASE_URL = $selected.storage
if (-not $SkipEnvPersist) {
    Set-UserEnv 'PUB_HOSTED_URL' $selected.pub
    Set-UserEnv 'FLUTTER_STORAGE_BASE_URL' $selected.storage
    Set-UserEnv 'PUB_CACHE' $PubCache
    Set-UserEnv 'GRADLE_USER_HOME' $GradleUserHome
    Set-UserEnv 'ANDROID_USER_HOME' $AndroidUserHome
    New-Item -ItemType Directory -Force -Path $PubCache, $GradleUserHome, $AndroidUserHome | Out-Null
    $env:PUB_CACHE = $PubCache
    $env:GRADLE_USER_HOME = $GradleUserHome
    $env:ANDROID_USER_HOME = $AndroidUserHome
}

# 2. Java
Write-Step "Java"
if (Test-Path (Join-Path $JavaHome 'bin\java.exe')) {
    $env:JAVA_HOME = $JavaHome
    if (-not $SkipEnvPersist) { Set-UserEnv 'JAVA_HOME' $JavaHome }
    $jdkBin = Join-Path $JavaHome 'bin'
    if (-not $SkipEnvPersist) { Add-UserPath $jdkBin }
    Write-Host "JAVA_HOME=$JavaHome" -ForegroundColor Green
} elseif (Get-Command java -ErrorAction SilentlyContinue) {
    $JavaHome = (Get-Command java).Source | Split-Path | Split-Path
    $env:JAVA_HOME = $JavaHome
    if (-not $SkipEnvPersist) { Set-UserEnv 'JAVA_HOME' $JavaHome }
    Write-Host "JAVA_HOME=$JavaHome (from PATH)" -ForegroundColor Green
} else {
    Write-Host "JAVA_HOME not set - install Android Studio or OpenJDK 17+" -ForegroundColor Yellow
}

# 3. Flutter PATH only (no flutter.bat call)
Write-Step "Flutter SDK path"
if (-not (Test-Path (Join-Path $FlutterRoot 'bin\flutter.bat'))) {
    throw "Flutter not found: $FlutterRoot"
}
$flutterBin = Join-Path $FlutterRoot 'bin'
$env:Path = "$flutterBin;$env:Path"
if (-not $SkipEnvPersist) { Add-UserPath $flutterBin }
if (-not $SkipEnvPersist) { Set-UserEnv 'FLUTTER_ROOT' $FlutterRoot }
$env:FLUTTER_ROOT = $FlutterRoot
Write-Host "FLUTTER_ROOT=$FlutterRoot" -ForegroundColor Green
Write-Host "Flutter bin on PATH" -ForegroundColor Green

# 4. Gradle mirrors
Write-Step "Gradle Maven mirrors"
Install-GradleMirrors

# 5. Android SDK - zip downloads first (fast)
if (-not $SkipAndroidSdk) {
    Write-Step "Android SDK (direct zip download)"
    New-Item -ItemType Directory -Force -Path $AndroidSdkRoot | Out-Null
    $env:ANDROID_HOME = $AndroidSdkRoot
    $env:ANDROID_SDK_ROOT = $AndroidSdkRoot
    if (-not $SkipEnvPersist) {
        Set-UserEnv 'ANDROID_HOME' $AndroidSdkRoot
        Set-UserEnv 'ANDROID_SDK_ROOT' $AndroidSdkRoot
    }
    Install-AndroidRepositoriesCfg
    Write-AndroidLicenses $AndroidSdkRoot

    Install-CmdlineToolsZip $AndroidSdkRoot
    $ptOk = Install-PlatformToolsZip $AndroidSdkRoot

    Add-UserPath (Join-Path $AndroidSdkRoot 'platform-tools')
    Add-UserPath (Join-Path $AndroidSdkRoot 'cmdline-tools\latest\bin')

    $sdkManager = Join-Path $AndroidSdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'
    if (-not $ptOk -and (Test-Path $sdkManager)) {
        Write-Host "Trying sdkmanager for platform-tools only..."
        Invoke-SdkManagerWithTimeout -SdkManager $sdkManager -SdkRoot $AndroidSdkRoot `
            -Packages @('platform-tools') -TimeoutSec $SdkManagerTimeoutSec
    }

    if ($UseSdkManagerPackages -and (Test-Path $sdkManager)) {
        Write-Step "Android SDK extra packages (sdkmanager, timeout ${SdkManagerTimeoutSec}s each)"
        Invoke-SdkManagerWithTimeout -SdkManager $sdkManager -SdkRoot $AndroidSdkRoot `
            -Packages $sdkManagerPackages -TimeoutSec $SdkManagerTimeoutSec
    }

    if (Test-Path (Join-Path $AndroidSdkRoot 'platform-tools\adb.exe')) {
        $v = & (Join-Path $AndroidSdkRoot 'platform-tools\adb.exe') version 2>&1 | Select-Object -First 1
        Write-Host "adb: $v" -ForegroundColor Green
    } else {
        Write-Host "adb not installed - open Android Studio -> SDK Manager -> Platform-Tools" -ForegroundColor Yellow
    }

    # flutter config via file (no flutter.bat)
    $flutterSettings = Join-Path $env:USERPROFILE '.flutter_settings'
    @(
        "android-sdk=$AndroidSdkRoot"
        'enable-analytics=false'
    ) | Set-Content $flutterSettings -Encoding UTF8
    Write-Host "Flutter android-sdk -> $AndroidSdkRoot (via settings file)" -ForegroundColor Green

    function Test-SdkPackagePresent([string]$SdkRoot) {
        @(
            (Test-Path "$SdkRoot\platforms\android-$CompileSdk\android.jar"),
            (Test-Path "$SdkRoot\build-tools\$BuildToolsVersion\aapt.exe"),
            (Test-Path "$SdkRoot\cmake\3.22.1\bin\cmake.exe")
        ) -notcontains $false
    }

    # CDN SDK packages when sdkmanager cannot reach Google (common in Iran)
    $pkgScript = Join-Path $ToolchainRoot 'scripts\install-android-sdk-packages-iran.ps1'
    if ((Test-Path $pkgScript) -and -not (Test-SdkPackagePresent $AndroidSdkRoot)) {
        Write-Host "Installing Android SDK packages via CDN redirector..."
        try {
            & $pkgScript -AndroidSdkRoot $AndroidSdkRoot -FlutterRoot $FlutterRoot
        } catch { Write-Host $_ -ForegroundColor Yellow }
    }
}

# 6. Optional flutter verify (with timeout - never blocks forever)
if ($VerifyFlutter) {
    Write-Step "Flutter verify (optional)"
    Invoke-FlutterVerify -FlutterBin $flutterBin -TimeoutSec $FlutterVerifyTimeoutSec -Mirror $selected
}

$sw.Stop()
Write-Step "Done in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s"
Write-Host @"

Configured (user env, NOT in package.json):
  PUB_HOSTED_URL=$($selected.pub)
  FLUTTER_STORAGE_BASE_URL=$($selected.storage)
  PUB_CACHE=$PubCache
  GRADLE_USER_HOME=$GradleUserHome
  ANDROID_USER_HOME=$AndroidUserHome
  ANDROID_HOME=$AndroidSdkRoot
  JAVA_HOME=$($env:JAVA_HOME)
  minSdk policy: $($script:MinAndroidApi) (Android 8.1+) in each project's build.gradle.kts

Next (new PowerShell window):
  powershell -ExecutionPolicy Bypass -File toolchain/scripts/verify-flutter-setup.ps1
  flutter doctor

NDK for release APK (~745 MB):
  powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-android-sdk-packages-iran.ps1 -IncludeNdk

Per Flutter project (first APK build):
  See toolchain/templates/flutter-android-mirrors.snippet.kts

Probe mirrors:
  powershell -ExecutionPolicy Bypass -File toolchain/scripts/probe-flutter-mirrors-iran.ps1

Persian guides:
  toolchain/docs/README-FA.md   (start — Web / Windows / Mobile)
  toolchain/docs/FLUTTER-SETUP-FA.md

"@ -ForegroundColor Green
