# Probe Flutter/Android mirrors — Iranian first, then fallbacks.
# Run: powershell -ExecutionPolicy Bypass -File toolchain/scripts/probe-flutter-mirrors-iran.ps1

$ErrorActionPreference = 'Continue'

function Test-Mirror {
    param(
        [string]$Name,
        [string]$Url,
        [ValidateSet('Head', 'Get')]
        [string]$Method = 'Get',
        [int]$TimeoutSec = 12
    )
    try {
        switch ($Method) {
            'Head' {
                $r = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec $TimeoutSec -UseBasicParsing
            }
            default {
                $r = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec $TimeoutSec -UseBasicParsing
            }
        }
        return @{ ok = $true; status = $r.StatusCode; name = $Name; url = $Url }
    } catch {
        return @{ ok = $false; status = $null; name = $Name; url = $Url; error = $_.Exception.Message }
    }
}

$probes = @(
    @{ name = 'pub-azs (IR)';           url = 'https://pub-azs.ir/api/packages/flutter'; method = 'Get' }
    @{ name = 'pub-myket (IR)';         url = 'https://pub.myket.ir/api/packages/flutter'; method = 'Get' }
    @{ name = 'maven-myket (IR)';       url = 'https://maven.myket.ir'; method = 'Head' }
    @{ name = 'storage-flutter-io';     url = 'https://storage.flutter-io.cn/flutter_infra_release/releases/releases_windows.json'; method = 'Get' }
    @{ name = 'pub-flutter-io';         url = 'https://pub.flutter-io.cn/api/packages/flutter'; method = 'Get' }
    @{ name = 'tuna-dart-pub';          url = 'https://mirrors.tuna.tsinghua.edu.cn/dart-pub/api/packages/flutter'; method = 'Get' }
    @{ name = 'android-cmdline-s13est'; url = 'https://wget.s13est.com/android/commandlinetools-win-13114758_latest.zip'; method = 'Head' }
    @{ name = 'pub.dev (official)';     url = 'https://pub.dev/api/packages/flutter'; method = 'Get' }
    @{ name = 'google-android-dl';      url = 'https://dl.google.com/android/repository/repository2-1.xml'; method = 'Head' }
)

Write-Host ""
Write-Host "=== Mirror probe (Iranian first) ===" -ForegroundColor Cyan
Write-Host ""

$ok = @()
$fail = @()

foreach ($p in $probes) {
    $r = Test-Mirror -Name $p.name -Url $p.url -Method $p.method
    if ($r.ok) {
        Write-Host ("OK   {0,-28} {1}" -f $r.name, $r.url) -ForegroundColor Green
        $ok += $r
    } else {
        Write-Host ("FAIL {0,-28} {1}" -f $r.name, $r.error) -ForegroundColor Red
        $fail += $r
    }
}

Write-Host ""
Write-Host "=== Recommended for your network ===" -ForegroundColor Cyan

# Prefer pub.myket.ir: pub-azs.ir sometimes fails pub content-hash verification
$pub = ($ok | Where-Object { $_.name -eq 'pub-myket (IR)' } | Select-Object -First 1)
if (-not $pub) { $pub = ($ok | Where-Object { $_.name -like 'pub-*' } | Select-Object -First 1) }
if ($pub) {
    $pubUrl = $pub.url -replace '/api/packages/flutter$', ''
    Write-Host "PUB_HOSTED_URL=$pubUrl"
    if ($pub.name -eq 'pub-azs (IR)') {
        Write-Host "  (tip: if flutter pub get fails on content-hash, switch to https://pub.myket.ir)" -ForegroundColor Yellow
    }
} else {
    $fallback = ($ok | Where-Object { $_.name -like 'pub-*' -or $_.name -like 'tuna*' } | Select-Object -First 1)
    if ($fallback) {
        $pubUrl = $fallback.url -replace '/api/packages/flutter$', ''
        Write-Host "PUB_HOSTED_URL=$pubUrl (fallback)"
    } else {
        Write-Host "PUB_HOSTED_URL=https://pub.dev (no mirror reachable - VPN may be needed)"
    }
}

$storage = ($ok | Where-Object { $_.name -like 'storage*' } | Select-Object -First 1)
if ($storage) {
    Write-Host "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"
} else {
    Write-Host "FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com"
}

$maven = ($ok | Where-Object { $_.name -like 'maven*' } | Select-Object -First 1)
if ($maven) { Write-Host "Gradle/Android Maven: $($maven.url)" }

Write-Host ""
Write-Host "OK: $($ok.Count)  FAIL: $($fail.Count)" -ForegroundColor $(if ($fail.Count -eq 0) { 'Green' } else { 'Yellow' })
