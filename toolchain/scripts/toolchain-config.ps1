# Shared toolchain layout (D: drive) + dynamic stable version resolution.
# Dot-source: . "$PSScriptRoot\toolchain-config.ps1"

. "$PSScriptRoot\download-resolver.ps1"

$script:ToolchainDevRoot       = 'D:\Dev'
$script:DefaultFlutterRoot     = Join-Path $script:ToolchainDevRoot 'flutter'
$script:DefaultAndroidSdkRoot  = Join-Path $script:ToolchainDevRoot 'Android\Sdk'
$script:DefaultJavaHome        = Join-Path $script:ToolchainDevRoot 'Java\jdk-17'
$script:DefaultPubCache        = Join-Path $script:ToolchainDevRoot '.pub-cache'
$script:DefaultGradleUserHome  = Join-Path $script:ToolchainDevRoot '.gradle'
$script:DefaultAndroidUserHome = Join-Path $script:ToolchainDevRoot '.android'
$script:DefaultVsInstallPath   = 'D:\Dev\VS2022BuildTools'
$script:DefaultCmakeWinRoot    = 'D:\Dev\cmake-win'
$script:MinAndroidApi          = 27
$script:DefaultProjectRoot     = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

function ConvertTo-FlutterSortKey([string]$Version) {
    if ($Version -match '^(\d+)\.(\d+)\.(\d+)') {
        return [long]$Matches[1] * 1000000 + [long]$Matches[2] * 1000 + [long]$Matches[3]
    }
    return 0
}

function Get-LatestFlutterStableRelease {
    $tiers = Get-FlutterReleaseMetadataUrls
    $json = Invoke-RestTiered -Label 'Flutter releases JSON' -UrlTiers $tiers
    if (-not $json) {
        return @{
            version               = '3.44.4'
            archive               = 'stable/windows/flutter_windows_3.44.4-stable.zip'
            hash                  = 'ad70ec4617166f1c38e5d2bfd388af71fda14f06'
            downloadBaseOfficial  = 'https://storage.googleapis.com/flutter_infra_release/releases'
            downloadBaseFallback  = 'https://storage.flutter-io.cn/flutter_infra_release/releases'
            channel               = 'stable'
        }
    }
    $stable = @($json.releases | Where-Object {
        $_.channel -eq 'stable' -and $_.version -match '^\d+\.\d+\.\d+$'
    })
    $latest = $stable | Sort-Object { ConvertTo-FlutterSortKey $_.version } -Descending | Select-Object -First 1
    $officialBase = 'https://storage.googleapis.com/flutter_infra_release/releases'
    $fallbackBase = if ($json.base_url -match 'googleapis') {
        'https://storage.flutter-io.cn/flutter_infra_release/releases'
    } else { $json.base_url }
    return @{
        version              = $latest.version
        archive              = $latest.archive
        hash                 = $latest.hash
        downloadBaseOfficial = $officialBase
        downloadBaseFallback = $fallbackBase
        channel              = 'stable'
    }
}

function Get-LatestTemurinJdk17 {
    $apiUrls = @{
        Primary  = @('https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows')
        Fallback = @()
        Iran     = @()
    }
    $assets = Invoke-RestTiered -Label 'Temurin JDK 17 API' -UrlTiers $apiUrls
    if ($assets) {
        $asset = @($assets)[0]
        return @{
            version = $asset.version.semver
            url     = $asset.binary.package.link
            sha256  = $asset.binary.package.checksum
        }
    }
    return @{
        version = '17.0.19+10'
        url     = 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.19%2B10/OpenJDK17U-jdk_x64_windows_hotspot_17.0.19_10.zip'
        sha256  = $null
    }
}

function Get-FlutterAndroidRequirements {
    param([string]$FlutterRoot)
    $req = @{
        CompileSdk       = 36
        BuildTools       = '34.0.0'
        BuildToolsShim   = '35.0.0'
        NdkVersion       = '27.0.12077973'
        CmakeVersion     = '3.22.1'
        PlatformZip      = 'platform-36_r02.zip'
        BuildToolsZip    = 'build-tools_r34-windows.zip'
        NdkZip           = 'android-ndk-r27-windows.zip'
        CmdlineToolsRev  = '13114758'
    }
    if (-not $FlutterRoot -or -not (Test-Path $FlutterRoot)) { return $req }

    $candidates = @(
        (Join-Path $FlutterRoot 'packages\flutter_tools\lib\src\android\gradle_utils.dart'),
        (Join-Path $FlutterRoot 'packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt'),
        (Join-Path $FlutterRoot 'packages\flutter_tools\templates\app\android.tmpl\app\build.gradle.kts.tmpl')
    )
    $quotedValue = '[^"]+'
    foreach ($file in $candidates) {
        if (-not (Test-Path $file)) { continue }
        $txt = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($txt -match ('compileSdkVersion\s*=\s*(\d+)')) { $req.CompileSdk = [int]$Matches[1] }
        if ($txt -match ('compileSdk\s*=\s*(\d+)')) { $req.CompileSdk = [int]$Matches[1] }
        if ($txt -match ('buildToolsVersion\s*=\s*"(' + $quotedValue + ')"')) { $req.BuildTools = $Matches[1] }
        if ($txt -match ('ndkVersion\s*=\s*"(' + $quotedValue + ')"')) { $req.NdkVersion = $Matches[1] }
    }

    $api = $req.CompileSdk
    $req.PlatformZip = "platform-${api}_r02.zip"
    if ($req.BuildTools -match '^(\d+)') {
        $req.BuildToolsZip = "build-tools_r$($Matches[1])-windows.zip"
    }
    if ($req.NdkVersion -match '^(\d+)') {
        $req.NdkZip = "android-ndk-r$($Matches[1])-windows.zip"
    }
    return $req
}

function Get-AndroidCmdlineToolsZipTiers {
    param([string]$Revision = '13114758')
    $leaf = "commandlinetools-win-${Revision}_latest.zip"
    return Get-AndroidSdkZipUrls -ZipLeaf $leaf
}

function Get-AndroidPlatformToolsZipTiers {
    $leaves = @('platform-tools-latest-windows.zip', 'platform-tools_r35.0.2-win.zip')
    $primary = @()
    $fallback = @()
    $iran = @()
    foreach ($leaf in $leaves) {
        $t = Get-AndroidSdkZipUrls -ZipLeaf $leaf
        $primary += $t.Primary
        $fallback += $t.Fallback
        $iran += $t.Iran
    }
    return @{ Primary = $primary; Fallback = $fallback; Iran = $iran }
}

function Ensure-DevDirectories {
    param(
        [string]$DevRoot = $script:ToolchainDevRoot,
        [string[]]$Extra = @()
    )
    $dirs = @(
        $DevRoot,
        (Join-Path $DevRoot 'flutter'),
        (Join-Path $DevRoot 'Android\Sdk'),
        (Join-Path $DevRoot 'Java'),
        (Join-Path $DevRoot '.pub-cache'),
        (Join-Path $DevRoot '.gradle'),
        (Join-Path $DevRoot '.android')
    ) + $Extra
    foreach ($d in $dirs | Select-Object -Unique) {
        if ($d) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    }
}

function Set-ToolchainUserEnv {
    param([hashtable]$Vars)
    foreach ($entry in $Vars.GetEnumerator()) {
        if ($null -eq $entry.Value -or $entry.Value -eq '') { continue }
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'User')
        Set-Item -Path ('Env:' + $entry.Key) -Value $entry.Value -ErrorAction SilentlyContinue
    }
}

function Get-VsWhereExe {
    $p = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $p) { return $p }
    return $null
}

function Get-VsInstallerExe {
    $p = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe'
    if (Test-Path $p) { return $p }
    return $null
}

function Test-WindowsDesktopToolchain {
    param([string]$ExpectedPath = $script:DefaultVsInstallPath)
    $vswhere = Get-VsWhereExe
    if (-not $vswhere) { return @{ ready = $false; reason = 'vswhere missing' } }

    $instPath = & $vswhere -latest -products * -property installationPath -format value 2>$null |
        Select-Object -First 1
    if (-not $instPath -and $ExpectedPath -and (Test-Path $ExpectedPath)) {
        $instPath = $ExpectedPath
    }
    $msvcRoot = if ($instPath) { Join-Path $instPath 'VC\Tools\MSVC' } else { $null }
    if (-not $msvcRoot -or -not (Test-Path $msvcRoot)) {
        return @{ ready = $false; reason = 'no VS installation with MSVC tools' }
    }

    $version = & $vswhere -latest -products * -property catalog_productLineVersion -format value 2>$null |
        Select-Object -First 1

    $sdkRoot = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0'
    $sdkOk = $false
    if (Test-Path $sdkRoot) {
        $folder = (Get-ItemProperty $sdkRoot -ErrorAction SilentlyContinue).InstallationFolder
        $sdkOk = [bool]$folder -and (Test-Path $folder)
    }
    if (-not $sdkOk -and $instPath) {
        $sdkOk = Test-Path (Join-Path $instPath 'SDK')
    }

    $cmakeExe = Get-ChildItem -Path $instPath -Recurse -Filter 'cmake.exe' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match 'CMake\\bin\\cmake\.exe$' } | Select-Object -First 1

    return @{
        ready    = $true
        path     = $instPath
        version  = $version
        sdkOk    = $sdkOk
        cmakeExe = if ($cmakeExe) { $cmakeExe.FullName } else { $null }
    }
}

function Test-SocksProxyAvailable {
    param(
        [string]$HostName = '127.0.0.1',
        [int]$Port = 10808,
        [int]$TimeoutMs = 800
    )
    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $connect = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $connect.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
        if (-not $client.Connected) { return $false }
        return $true
    } catch {
        return $false
    } finally {
        if ($client) { $client.Close() }
    }
}

function Get-GradleJvmArgs {
    param([bool]$SocksAvailable = (Test-SocksProxyAvailable))
    $base = '-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError -Djava.net.useSystemProxies=false'
    if ($SocksAvailable) {
        return "$base -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=10808"
    }
    return $base
}

function Write-GradleUserProperties {
    param(
        [string]$GradleUserHome = $script:DefaultGradleUserHome,
        [bool]$SocksAvailable = (Test-SocksProxyAvailable)
    )
    New-Item -ItemType Directory -Force -Path $GradleUserHome | Out-Null
    $gradleProps = Join-Path $GradleUserHome 'gradle.properties'
    $lines = @(
        '# Flutter/Android builds - see toolchain/templates/gradle-user.properties',
        'systemProp.java.net.useSystemProxies=false'
    )
    if ($SocksAvailable) {
        $lines += 'systemProp.socksProxyHost=127.0.0.1'
        $lines += 'systemProp.socksProxyPort=10808'
    }
    $lines | Set-Content $gradleProps -Encoding UTF8
    return @{ path = $gradleProps; socks = $SocksAvailable }
}

function Add-ToolchainUserPath {
    param([string[]]$Segments)
    $Segments = @('C:\Windows\System32', 'C:\Program Files\Git\cmd') + $Segments
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($userPath -split ';' | Where-Object { $_ })
    foreach ($seg in $Segments) {
        if (-not $seg) { continue }
        if ($seg -match 'Git\\cmd' -and -not (Test-Path $seg)) { continue }
        if ($parts -notcontains $seg) { $parts += $seg }
    }
    $joined = ($parts -join ';')
    [Environment]::SetEnvironmentVariable('Path', $joined, 'User')
    $env:Path = $joined + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
}

function Select-PubStorageMirrors {
    param([ValidateSet('auto', 'iran', 'china', 'official')][string]$Mode = 'auto')
    $official = @{ id = 'official'; pub = 'https://pub.dev'; storage = 'https://storage.googleapis.com' }
    $china    = @{ id = 'china-cfug'; pub = 'https://pub.flutter-io.cn'; storage = 'https://storage.flutter-io.cn' }
    $iranMyket = @{ id = 'pub-myket'; pub = 'https://pub.myket.ir'; storage = 'https://storage.flutter-io.cn' }
    $iranAzs   = @{ id = 'pub-azs'; pub = 'https://pub-azs.ir'; storage = 'https://storage.flutter-io.cn' }

    if ($Mode -eq 'official') { return $official }
    if ($Mode -eq 'china') { return $china }

    # Tier order: official -> china -> iran (probe each)
    $candidates = @($official, $china, $iranMyket)
    if ($Mode -eq 'auto') { $candidates += $iranAzs }
    foreach ($m in $candidates) {
        try {
            $r = Invoke-WebRequest -Uri "$($m.pub)/api/packages/flutter" -Method Get -TimeoutSec 6 -UseBasicParsing
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400) {
                Write-DownloadLog "  Pub mirror selected: $($m.id) ($($m.pub))" 'ok'
                return $m
            }
        } catch { }
    }
    return $iranMyket
}

function Initialize-ToolchainSessionEnv {
    param(
        [string]$FlutterRoot = $script:DefaultFlutterRoot,
        [string]$AndroidSdkRoot = $script:DefaultAndroidSdkRoot,
        [string]$JavaHome = $script:DefaultJavaHome,
        [string]$PubCache = $script:DefaultPubCache,
        [string]$GradleUserHome = $script:DefaultGradleUserHome
    )
    $env:FLUTTER_ROOT = $FlutterRoot
    $env:JAVA_HOME = $JavaHome
    $env:ANDROID_HOME = $AndroidSdkRoot
    $env:ANDROID_SDK_ROOT = $AndroidSdkRoot
    $env:PUB_CACHE = $PubCache
    $env:GRADLE_USER_HOME = $GradleUserHome
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $jdkBin = if ($JavaHome) { Join-Path $JavaHome 'bin' } else { $null }
    $prefix = @('C:\Windows\System32', 'C:\Program Files\Git\cmd')
    if ($jdkBin -and (Test-Path (Join-Path $jdkBin 'java.exe'))) { $prefix = @($jdkBin) + $prefix }
    $env:Path = ($prefix -join ';') + ';' + $userPath + ';' + $machinePath
}
