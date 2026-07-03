# Comprehensive toolchain tests: parse, unit logic, tier order, optional live verify.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File toolchain/tests/Run-ToolchainTests.ps1
#   powershell -ExecutionPolicy Bypass -File toolchain/tests/Run-ToolchainTests.ps1 -IncludeNetwork
#   powershell -ExecutionPolicy Bypass -File toolchain/tests/Run-ToolchainTests.ps1 -IncludeLiveVerify

param(
    [switch]$IncludeNetwork,
    [switch]$IncludeLiveVerify
)

$ErrorActionPreference = 'Stop'
$toolchainRoot = Split-Path -Parent $PSScriptRoot
$scriptsDir = Join-Path $toolchainRoot 'scripts'

. (Join-Path $scriptsDir 'toolchain-config.ps1')

$passed = 0
$failed = 0

function Assert-Test {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "       $Detail" }
        $script:failed++
    }
}

Write-Host "`n=== Toolchain Tests ===" -ForegroundColor Cyan

# 1) All scripts parse
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
$testScriptNames = @('Run-ToolchainTests.ps1', 'Run-SmokeTests.ps1')
foreach ($name in $scriptNames) {
    $path = Join-Path $scriptsDir $name
    if (-not (Test-Path $path)) {
        Assert-Test "exists: $name" $false
        continue
    }
    $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errs)
    Assert-Test "parse: $name" ($null -eq $errs -or $errs.Count -eq 0) $(if ($errs) { $errs[0].Message })
}
foreach ($name in $testScriptNames) {
    $path = Join-Path $PSScriptRoot $name
    if (-not (Test-Path $path)) {
        Assert-Test "exists: $name" $false
        continue
    }
    $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errs)
    Assert-Test "parse: $name" ($null -eq $errs -or $errs.Count -eq 0) $(if ($errs) { $errs[0].Message })
}

# 2) Version sort logic
Assert-Test 'ConvertTo-FlutterSortKey 3.44.4 > 3.38.5' `
    ((ConvertTo-FlutterSortKey '3.44.4') -gt (ConvertTo-FlutterSortKey '3.38.5'))
Assert-Test 'Test-NeedsVersionUpgrade newer' `
    (Test-NeedsVersionUpgrade -Installed '3.38.5' -Latest '3.44.4')
Assert-Test 'Test-NeedsVersionUpgrade same' `
    (-not (Test-NeedsVersionUpgrade -Installed '3.44.4' -Latest '3.44.4'))
Assert-Test 'Test-NeedsVersionUpgrade fresh install' `
    (Test-NeedsVersionUpgrade -Installed $null -Latest '3.44.4')

# 3) Tier URL order (official before iran)
$androidTiers = Get-AndroidSdkZipUrls -ZipLeaf 'build-tools_r34-windows.zip'
Assert-Test 'Android primary includes dl.google.com' `
    ($androidTiers.Primary -contains 'https://dl.google.com/android/repository/build-tools_r34-windows.zip')
Assert-Test 'Android iran includes s13est' `
    ($androidTiers.Iran -contains 'https://wget.s13est.com/android/build-tools_r34-windows.zip')
Assert-Test 'Android primary before iran in tier list' `
    ($androidTiers.Primary[0] -notmatch 's13est')

$releaseStub = @{
    archive              = 'stable/windows/flutter_windows_3.44.4-stable.zip'
    downloadBaseOfficial = 'https://storage.googleapis.com/flutter_infra_release/releases'
    downloadBaseFallback = 'https://storage.flutter-io.cn/flutter_infra_release/releases'
}
$flutterTiers = Get-FlutterSdkZipUrls -Release $releaseStub
Assert-Test 'Flutter primary uses googleapis' `
    ($flutterTiers.Primary[0] -match 'googleapis')
Assert-Test 'Flutter fallback uses flutter-io.cn' `
    ($flutterTiers.Fallback[0] -match 'flutter-io\.cn')

Assert-Test 'VS bootstrapper primary is aka.ms' `
    ((Get-VsBuildToolsBootstrapperUrls).Primary[0] -match 'aka\.ms')

$vsComps = Get-FlutterRequiredVsComponents
Assert-Test 'VS components include VCTools workload' `
    ($vsComps -contains 'Microsoft.VisualStudio.Workload.VCTools')
Assert-Test 'VS components include Windows SDK 26100' `
    ($vsComps -contains 'Microsoft.VisualStudio.Component.Windows11SDK.26100')

$cmakeTiers = Get-CmakeStandaloneWindowsUrls -Version '3.31.6'
Assert-Test 'CMake primary is GitHub releases' `
    ($cmakeTiers.Primary[0] -match 'github\.com/Kitware/CMake')
Assert-Test 'CMake iran mirror is s13est' `
    ($cmakeTiers.Iran[0] -match 's13est')

Assert-Test 'Test-SocksProxyAvailable returns bool' `
    ((Test-SocksProxyAvailable) -is [bool])

# 4) Min Android API policy
Assert-Test 'minSdk policy is 27 (Android 8.1+)' ($script:MinAndroidApi -eq 27)

# 5) Project files
$projectRoot = Split-Path -Parent $toolchainRoot
$appGradle = Join-Path $projectRoot 'android\app\build.gradle.kts'
if (Test-Path $appGradle) {
    $txt = Get-Content $appGradle -Raw
    Assert-Test 'project minSdk 27' ($txt -match 'minSdk\s*=\s*27')
}

# 5b) Windows desktop detection (live, no mock)
$winLive = Test-WindowsDesktopToolchain
Assert-Test 'Test-WindowsDesktopToolchain (live)' $winLive.ready $(if ($winLive.ready) { $winLive.path } else { $winLive.reason })

# 6) Optional network
if ($IncludeNetwork) {
  Write-Host "`n--- Network tests ---" -ForegroundColor Cyan
  try {
    $rel = Get-LatestFlutterStableRelease
    Assert-Test 'Get-LatestFlutterStableRelease' ($rel.version -match '^\d+\.\d+\.\d+$') $rel.version
  } catch {
    Assert-Test 'Get-LatestFlutterStableRelease' $false $_.Exception.Message
  }
  try {
    $jdk = Get-LatestTemurinJdk17
    Assert-Test 'Get-LatestTemurinJdk17' ($jdk.url -match '^https://') $jdk.url
  } catch {
    Assert-Test 'Get-LatestTemurinJdk17' $false $_.Exception.Message
  }
}

# 7) Optional live verify script
if ($IncludeLiveVerify) {
  Write-Host "`n--- Live verify ---" -ForegroundColor Cyan
  $verify = Join-Path $scriptsDir 'verify-flutter-setup.ps1'
  $p = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-ExecutionPolicy', 'Bypass', '-File', $verify, '-Strict', '-SkipDoctor'
  ) -Wait -PassThru -NoNewWindow
  Assert-Test 'verify-flutter-setup.ps1 -Strict' ($p.ExitCode -eq 0) "exit $($p.ExitCode)"

  Initialize-ToolchainSessionEnv
  $jdkBin = Join-Path $script:DefaultJavaHome 'bin\java.exe'
  $javaCmd = Get-Command java -ErrorAction SilentlyContinue
  Assert-Test 'java resolves to JAVA_HOME' ($javaCmd.Source -ieq $jdkBin) $(if ($javaCmd) { $javaCmd.Source })

  Set-Location $projectRoot
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $testOut = & flutter test 2>&1 | Out-String
  $testExit = $LASTEXITCODE
  $ErrorActionPreference = $prevEap
  $testCount = 0
  if ($testOut -match '\+(\d+): All tests passed') { $testCount = [int]$Matches[1] }
  Assert-Test 'flutter test count (live) >= 38' ($testExit -eq 0 -and $testCount -ge 38) "exit $testExit ran $testCount"
}

Write-Host "`n=== Summary: $passed passed, $failed failed ===" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
exit $failed
