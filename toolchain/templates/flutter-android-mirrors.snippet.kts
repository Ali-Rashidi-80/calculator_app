// Add inside pluginManagement { repositories { ... } } in android/settings.gradle.kts
// Required for first APK build when Google Maven is blocked.

    maven { url = uri("https://maven.myket.ir") }
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }

// Add inside android/build.gradle.kts allprojects { repositories { ... } }:

    maven { url = uri("https://maven.myket.ir") }
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    maven { url = uri("https://maven.aliyun.com/repository/public") }

// Gradle wrapper — use Tencent mirror (in android/gradle/wrapper/gradle-wrapper.properties):
// distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-8.14-all.zip

// Per-project android/gradle.properties (append to defaults):
// org.gradle.jvmargs=... -Djava.net.useSystemProxies=false -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=10808

// minSdk Android 8.1+ in android/app/build.gradle.kts:
// minSdk = 27
