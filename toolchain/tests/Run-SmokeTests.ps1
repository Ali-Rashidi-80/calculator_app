# Honest end-to-end smoke tests — no mocked passes, real builds and artifacts checked.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/tests/Run-SmokeTests.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/tests/Run-SmokeTests.ps1 -SkipBuilds
#   powershell -ExecutionPolicy Bypass -File toolchain/tests/Run-SmokeTests.ps1 -SkipEmulator

param(
    [string]$ProjectRoot = 'D:\0\calculator_app\calculator_app',
    [switch]$SkipBuilds,
    [switch]$SkipEmulator
)

$ErrorActionPreference = 'Continue'
$toolchainRoot = Split-Path -Parent $PSScriptRoot
$scriptsDir = Join-Path $toolchainRoot 'scripts'

. (Join-Path $scriptsDir 'toolchain-config.ps1')
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

$passed = 0
$failed = 0

function Assert-Smoke {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
        if ($Detail) { Write-Host "       $Detail" }
        $script:passed++
    } else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "       $Detail" }
        $script:failed++
    }
}

Write-Host "`n=== Smoke Tests (honest / no shortcuts) ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot`n"

# 1) Unit + toolchain logic tests
$toolchainTest = Join-Path $PSScriptRoot 'Run-ToolchainTests.ps1'
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
$p = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-ExecutionPolicy', 'Bypass', '-File', $toolchainTest, '-IncludeNetwork'
) -Wait -PassThru -NoNewWindow
$ErrorActionPreference = $prevEap
Assert-Smoke 'Run-ToolchainTests.ps1 (network)' ($p.ExitCode -eq 0) "exit $($p.ExitCode)"

# 2) Strict verify (filesystem + env, no doctor noise)
$verify = Join-Path $scriptsDir 'verify-flutter-setup.ps1'
$p = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-ExecutionPolicy', 'Bypass', '-File', $verify, '-Strict', '-SkipDoctor'
) -Wait -PassThru -NoNewWindow
Assert-Smoke 'verify-flutter-setup.ps1 -Strict' ($p.ExitCode -eq 0) "exit $($p.ExitCode)"

# 3) Windows desktop toolchain probe
$win = Test-WindowsDesktopToolchain
Assert-Smoke 'Test-WindowsDesktopToolchain.ready' $win.ready $(if ($win.ready) { $win.path } else { $win.reason })
Assert-Smoke 'Test-WindowsDesktopToolchain.cmake' ([bool]$win.cmakeExe) $win.cmakeExe

# 4) JAVA_HOME vs PATH java (no Oracle JRE shadowing)
$jdkJava = Join-Path $script:DefaultJavaHome 'bin\java.exe'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
Assert-Smoke 'PATH contains JDK bin' ($userPath -contains (Join-Path $script:DefaultJavaHome 'bin'))
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
Assert-Smoke 'java resolves to Temurin 17' ($javaCmd.Source -ieq $jdkJava) $(if ($javaCmd) { $javaCmd.Source })

Set-Location $ProjectRoot

# 5) Flutter tests — parse real count from output
$testOut = & flutter test 2>&1 | Out-String
$testExit = $LASTEXITCODE
$testCount = 0
if ($testOut -match '\+(\d+): All tests passed') { $testCount = [int]$Matches[1] }
Assert-Smoke 'flutter test exit 0' ($testExit -eq 0) "exit $testExit"
Assert-Smoke 'flutter test count >= 38' ($testCount -ge 38) "ran $testCount tests"

# 5c) All lib sources present (no orphan modules)
$libFiles = @(
    'lib\main.dart', 'lib\calculator.dart', 'lib\ui\calculator_page.dart',
    'lib\ui\widgets\calc_button.dart', 'lib\ui\widgets\calc_keypad.dart',
    'lib\ui\widgets\calc_display_panel.dart', 'lib\theme\app_theme.dart'
)
foreach ($lf in $libFiles) {
    Assert-Smoke "lib exists: $lf" (Test-Path (Join-Path $ProjectRoot $lf))
}

# 5b) Static analysis — no suppressed failures
$analyzeOut = (& flutter analyze 2>&1 | Out-String)
Assert-Smoke 'flutter analyze exit 0' ($LASTEXITCODE -eq 0) $(($analyzeOut -split "`n" | Select-Object -Last 2) -join ' ')

# 6) flutter doctor — key toolchains must report ready (avoid Unicode checkmark encoding issues)
$doctorOut = (& flutter doctor -v 2>&1 | Out-String)
$vsOk = $doctorOut -match 'Visual Studio - develop Windows apps' -and $doctorOut -notmatch '\[X\].*Visual Studio'
Assert-Smoke 'flutter doctor: Visual Studio OK' $vsOk $(if ($vsOk) { 'develop Windows apps' } else { 'VS section missing or failed' })
$androidOk = $doctorOut -match 'Android toolchain - develop for Android' -and $doctorOut -notmatch '\[X\].*Android toolchain'
Assert-Smoke 'flutter doctor: Android OK' $androidOk $(if ($androidOk) { 'develop for Android' } else { 'Android section missing or failed' })

# 6b) Gradle proxy policy matches live SOCKS state (no stale config)
$socksLive = Test-SocksProxyAvailable
$gradlePropsPath = Join-Path $script:DefaultGradleUserHome 'gradle.properties'
if (Test-Path $gradlePropsPath) {
    $gradleTxt = Get-Content $gradlePropsPath -Raw
    $gradleHasSocks = $gradleTxt -match 'socksProxyHost'
    Assert-Smoke 'Gradle SOCKS config matches proxy availability' ($gradleHasSocks -eq $socksLive) `
        $(if ($socksLive) { 'SOCKS on + config present' } else { 'SOCKS off + no stale config' })
}

# 6c) Idempotent toolchain scripts (must not fail when already installed)
foreach ($pair in @(
    @{ Name = 'install-windows-desktop-toolchain.ps1'; File = 'install-windows-desktop-toolchain.ps1' }
    @{ Name = 'patch-flutter-gradle-mirrors.ps1'; File = 'patch-flutter-gradle-mirrors.ps1' }
)) {
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $scriptsDir $pair.File)
    ) -Wait -PassThru -NoNewWindow
    Assert-Smoke "$($pair.Name) idempotent" ($p.ExitCode -eq 0) "exit $($p.ExitCode)"
}

if (-not $SkipBuilds) {
    Write-Host "`n--- Production builds ---" -ForegroundColor Cyan
    $buildArgs = @('-ExecutionPolicy', 'Bypass', '-File', (Join-Path $scriptsDir 'run-production-builds.ps1'))
    if ($SkipEmulator) { $buildArgs += '-SkipEmulator' }
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $buildArgs -Wait -PassThru -NoNewWindow
    Assert-Smoke 'run-production-builds.ps1' ($p.ExitCode -eq 0) "exit $($p.ExitCode)"

    # 7) Artifact integrity (not just exit codes)
    $apk = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    Assert-Smoke 'APK artifact exists' (Test-Path $apk) $apk
    if (Test-Path $apk) {
        Assert-Smoke 'APK size > 1 MB' ((Get-Item $apk).Length -gt 1MB) "$([math]::Round((Get-Item $apk).Length/1MB, 2)) MB"
        $aapt = Join-Path $env:ANDROID_HOME 'build-tools\34.0.0\aapt.exe'
        if (Test-Path $aapt) {
            $badging = & $aapt dump badging $apk 2>&1 | Out-String
            Assert-Smoke 'APK minSdkVersion 27' ($badging -match "sdkVersion:\s*'27'") $badging
            Assert-Smoke 'APK targetSdkVersion 36' ($badging -match "targetSdkVersion:\s*'36'") `
                $(($badging -split "`n" | Where-Object { $_ -match 'targetSdkVersion' } | Select-Object -First 1))
            Assert-Smoke 'APK native arm64-v8a' ($badging -match "native-code:.*'arm64-v8a'") `
                $(($badging -split "`n" | Where-Object { $_ -match 'native-code' } | Select-Object -First 1))
        }
    }

    $webIndex = Join-Path $ProjectRoot 'build\web\index.html'
    Assert-Smoke 'Web index.html exists' (Test-Path $webIndex)
    if (Test-Path $webIndex) {
        $webTxt = Get-Content $webIndex -Raw
        Assert-Smoke 'Web bundle referenced' ($webTxt -match 'flutter_bootstrap|main\.dart\.js') 'index.html'
        $webJs = @(
            (Join-Path $ProjectRoot 'build\web\main.dart.js'),
            (Join-Path $ProjectRoot 'build\web\flutter_bootstrap.js')
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
        Assert-Smoke 'Web JS bundle on disk' ([bool]$webJs) $(if ($webJs) { $webJs } else { 'no main.dart.js or flutter_bootstrap.js' })
    }

    $winExe = Join-Path $ProjectRoot 'build\windows\x64\runner\Release\calculator_app.exe'
    Assert-Smoke 'Windows exe exists' (Test-Path $winExe) $winExe
    if (Test-Path $winExe) {
        $exeInfo = Get-Item $winExe
        Assert-Smoke 'Windows exe size > 50 KB' ($exeInfo.Length -gt 50KB) "$([math]::Round($exeInfo.Length/1KB, 0)) KB"
        $pe = [System.IO.File]::ReadAllBytes($winExe)
        $peOk = $pe.Length -ge 2 -and $pe[0] -eq 0x4D -and $pe[1] -eq 0x5A
        Assert-Smoke 'Windows exe PE header MZ' $peOk $(if ($peOk) { 'valid PE' } else { 'invalid PE' })
    }

    $flutterDll = Join-Path $ProjectRoot 'build\windows\x64\runner\Release\flutter_windows.dll'
    Assert-Smoke 'Windows flutter_windows.dll exists' (Test-Path $flutterDll)
}

Write-Host "`n=== Smoke summary: $passed passed, $failed failed ===" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
exit $failed
