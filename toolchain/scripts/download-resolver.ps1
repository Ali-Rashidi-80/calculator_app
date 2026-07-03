# Tiered download resolver: official/external first, Iranian mirrors last.
# Dot-sourced from toolchain-config.ps1

$script:TieredRetriesPerUrl = 2
$script:TieredConnectTimeoutSec = 30
$script:TieredProxyFallback = 'socks5h://127.0.0.1:10808'

function Write-DownloadLog {
    param([string]$Message, [string]$Tier = 'info')
    $color = switch ($Tier) {
        'primary' { 'Cyan' }
        'fallback' { 'Yellow' }
        'iran' { 'Magenta' }
        'ok' { 'Green' }
        'err' { 'Red' }
        default { 'Gray' }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-UrlReachable {
    param([string]$Url, [int]$TimeoutSec = 8, [long]$MinContentLength = 0)
    try {
        $r = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec $TimeoutSec -UseBasicParsing
        if ($r.StatusCode -lt 200 -or $r.StatusCode -ge 400) { return $false }
        $len = $r.Headers['Content-Length']
        if ($null -ne $len -and [long]$len -lt $MinContentLength) { return $false }
        return $true
    } catch { return $false }
}

function Invoke-SingleDownloadAttempt {
    param(
        [string]$Url,
        [string]$Dest,
        [int]$MaxTimeSec = 900,
        [string]$ProxyUrl = '',
        [switch]$Resume
    )
    if (-not $Resume -and (Test-Path $Dest)) { Remove-Item -Force $Dest -ErrorAction SilentlyContinue }
    $curlArgs = @(
        '-L', '--connect-timeout', "$script:TieredConnectTimeoutSec",
        '--max-time', "$MaxTimeSec", '--retry', '2', '--retry-delay', '3',
        '-o', $Dest
    )
    if ($Resume) { $curlArgs += '-C', '-' }
    if ($ProxyUrl) { $curlArgs = @('-x', $ProxyUrl) + $curlArgs }
    $curlArgs += $Url
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & curl.exe @curlArgs 2>$null
    $curlExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($curlExit -eq 0 -and (Test-Path $Dest)) { return $true }
    try {
        $ProgressPreference = 'SilentlyContinue'
        if ($ProxyUrl) {
            Invoke-WebRequest -Uri $Url -OutFile $Dest -TimeoutSec $MaxTimeSec -Proxy $ProxyUrl -UseBasicParsing
        } else {
            Invoke-WebRequest -Uri $Url -OutFile $Dest -TimeoutSec $MaxTimeSec -UseBasicParsing
        }
        return (Test-Path $Dest)
    } catch {
        try {
            Start-BitsTransfer -Source $Url -Destination $Dest -TransferType Download -Priority Foreground -ErrorAction Stop
            return (Test-Path $Dest)
        } catch { return $false }
    }
}

function Invoke-TieredDownload {
    param(
        [string]$Label,
        [string[]]$PrimaryUrls,
        [string[]]$FallbackUrls = @(),
        [string[]]$IranUrls = @(),
        [string]$Dest,
        [long]$MinBytes = 500KB,
        [int]$MaxTimeSec = 900,
        [switch]$Resume,
        [switch]$TryProxyOnFailure
    )
    $tiers = @(
        @{ name = 'primary (official/external)'; urls = $PrimaryUrls; proxy = '' }
        @{ name = 'fallback (regional mirrors)'; urls = $FallbackUrls; proxy = '' }
        @{ name = 'iran (local mirrors)'; urls = $IranUrls; proxy = '' }
    )
    if ($TryProxyOnFailure) {
        $tiers += @(
            @{ name = 'primary via SOCKS'; urls = $PrimaryUrls; proxy = $script:TieredProxyFallback }
            @{ name = 'fallback via SOCKS'; urls = $FallbackUrls; proxy = $script:TieredProxyFallback }
            @{ name = 'iran via SOCKS'; urls = $IranUrls; proxy = $script:TieredProxyFallback }
        )
    }
    Write-DownloadLog "[$Label] tiered download -> $Dest"
    foreach ($tier in $tiers) {
        if (-not $tier.urls -or $tier.urls.Count -eq 0) { continue }
        $tierColor = if ($tier.name -match 'iran') { 'iran' } elseif ($tier.name -match 'fallback') { 'fallback' } else { 'primary' }
        Write-DownloadLog "  tier: $($tier.name)" $tierColor
        foreach ($url in ($tier.urls | Select-Object -Unique)) {
            for ($attempt = 1; $attempt -le $script:TieredRetriesPerUrl; $attempt++) {
                Write-DownloadLog "    try $attempt/$($script:TieredRetriesPerUrl): $url"
                $ok = Invoke-SingleDownloadAttempt -Url $url -Dest $Dest -MaxTimeSec $MaxTimeSec -ProxyUrl $tier.proxy -Resume:$Resume
                if ($ok -and (Test-Path $Dest) -and (Get-Item $Dest).Length -ge $MinBytes) {
                    $mb = [math]::Round((Get-Item $Dest).Length / 1MB, 1)
                    Write-DownloadLog "  [$Label] OK ($mb MB) from $url" 'ok'
                    return @{ success = $true; url = $url; tier = $tier.name }
                }
            }
        }
    }
    Write-DownloadLog "  [$Label] all tiers failed" 'err'
    return @{ success = $false; url = $null; tier = $null }
}

function Get-FlutterReleaseMetadataUrls {
    return @{
        Primary  = @('https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json')
        Fallback = @('https://storage.flutter-io.cn/flutter_infra_release/releases/releases_windows.json')
        Iran     = @()
    }
}

function Get-FlutterSdkZipUrls {
    param([hashtable]$Release)
    $rel = $Release.archive
    return @{
        Primary  = @("$($Release.downloadBaseOfficial)/$rel")
        Fallback = @("$($Release.downloadBaseFallback)/$rel")
        Iran     = @("https://wget.s13est.com/flutter/$($rel.Split('/')[-1])")
    }
}

function Get-AndroidSdkZipUrls {
    param([string]$ZipLeaf)
    $cdn = 'https://redirector.gvt1.com/edgedl/android/repository'
    return @{
        Primary  = @(
            "https://dl.google.com/android/repository/$ZipLeaf"
            "https://mirrors.cloud.tencent.com/AndroidSDK/$ZipLeaf"
            "https://mirrors.aliyun.com/android/repository/$ZipLeaf"
        )
        Fallback = @("$cdn/$ZipLeaf")
        Iran     = @("https://wget.s13est.com/android/$ZipLeaf")
    }
}

function Get-JdkDownloadUrls {
    param([hashtable]$JdkInfo)
    $github = $JdkInfo.url
    return @{
        Primary  = @($github)
        Fallback = @()
        Iran     = @("https://wget.s13est.com/java/$($github.Split('/')[-1])")
    }
}

function Get-VsBuildToolsBootstrapperUrls {
    return @{
        Primary  = @(
            'https://aka.ms/vs/17/release/vs_BuildTools.exe'
            'https://download.visualstudio.microsoft.com/download/pr/6aa9c773-953a-4a8a-9785-070ae308beb3/501ee2c2db507875ae5347eaa67a135/vs_BuildTools.exe'
        )
        Fallback = @(
            'https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=17&os=windows'
        )
        Iran     = @()
    }
}

function Get-CmakeStandaloneWindowsUrls {
    param([string]$Version = '3.31.6')
    $leaf = "cmake-$Version-windows-x86_64.zip"
    $majorMinor = (($Version -split '\.')[0..1]) -join '.'
    return @{
        Primary  = @(
            "https://github.com/Kitware/CMake/releases/download/v$Version/$leaf"
            "https://cmake.org/files/v$majorMinor/$leaf"
        )
        Fallback = @(
            "https://mirrors.tencent.com/Kitware/CMake/$leaf"
        )
        Iran     = @("https://wget.s13est.com/cmake/$leaf")
    }
}

function Get-FlutterRequiredVsComponents {
  return @(
    'Microsoft.VisualStudio.Workload.VCTools'
    'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
    'Microsoft.VisualStudio.Component.VC.CMake.Project'
    'Microsoft.VisualStudio.Component.Windows11SDK.22621'
    'Microsoft.VisualStudio.Component.Windows11SDK.26100'
  )
}

function Get-InstalledFlutterVersion {
    param([string]$FlutterRoot)
    if (-not $FlutterRoot -or -not (Test-Path $FlutterRoot)) { return $null }
    $versionFile = Join-Path $FlutterRoot 'version'
    if (Test-Path $versionFile) {
        $v = (Get-Content $versionFile -Raw -ErrorAction SilentlyContinue).Trim()
        if ($v -match '(\d+\.\d+\.\d+)') { return $Matches[1] }
    }
    $flutterBat = Join-Path $FlutterRoot 'bin\flutter.bat'
    if (-not (Test-Path $flutterBat)) { return $null }
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = cmd /c "`"$flutterBat`" --version 2>&1" | Select-Object -First 1
    $ErrorActionPreference = $oldEap
    if ($out -match 'Flutter\s+(\d+\.\d+\.\d+)') { return $Matches[1] }
    return $null
}

function Get-InstalledJdkVersion {
    param([string]$JavaHome)
    $javaExe = Join-Path $JavaHome 'bin\java.exe'
    if (-not (Test-Path $javaExe)) { return $null }
    $line = cmd /c "`"$javaExe`" -version 2>&1" | Select-Object -First 1
    if ($line -match '"(\d+\.\d+\.\d+)') { return $Matches[1] }
    return $null
}

function Test-NeedsVersionUpgrade {
    param([string]$Installed, [string]$Latest)
    if (-not $Installed) { return $true }
    if (-not $Latest) { return $false }
    $iKey = ConvertTo-FlutterSortKey $Installed
    $lKey = ConvertTo-FlutterSortKey $Latest
    return ($lKey -gt $iKey)
}

function Remove-OldToolchainDirectory {
    param([string]$Path, [string]$Label)
    if (-not $Path -or -not (Test-Path $Path)) { return }
    Write-DownloadLog "  removing old $Label : $Path" 'fallback'
    Remove-Item -Recurse -Force $Path -ErrorAction SilentlyContinue
}

function Invoke-RestTiered {
    param(
        [string]$Label,
        [hashtable]$UrlTiers,
        [int]$TimeoutSec = 25
    )
    foreach ($tierName in @('Primary', 'Fallback', 'Iran')) {
        $urls = $UrlTiers[$tierName]
        if (-not $urls) { continue }
        Write-DownloadLog "[$Label] REST tier: $tierName" $(if ($tierName -eq 'Iran') { 'iran' } elseif ($tierName -eq 'Fallback') { 'fallback' } else { 'primary' })
        foreach ($url in $urls) {
            for ($i = 1; $i -le $script:TieredRetriesPerUrl; $i++) {
                try {
                    return Invoke-RestMethod -Uri $url -TimeoutSec $TimeoutSec -UseBasicParsing
                } catch {
                    Write-DownloadLog "    REST fail ($i): $url" 'err'
                }
            }
        }
    }
    return $null
}
