# راهنمای توسعه‌دهنده موبایل (Android) — calculator_app

> **مخاطب:** توسعه‌دهندگانی که **APK Android** می‌سازند (Android 8.1 Oreo و بالاتر)  
> **minSdk:** 27 (Android 8.1+) — **compileSdk:** پویا از Flutter stable (فعلاً 36)  
> **نصب toolchain:** [FLUTTER-SETUP-FA.md](FLUTTER-SETUP-FA.md) — **الزامی** برای اولین build

---

## فهرست

1. [پیش‌نیاز](#پیش‌نیاز)
2. [نصب toolchain (خلاصه)](#نصب-toolchain-خلاصه)
3. [اولین اجرا روی دستگاه](#اولین-اجرا-روی-دستگاه)
4. [Emulator Android Studio](#emulator-android-studio)
5. [توسعه روزمره](#توسعه-روزمره)
6. [ساخت APK Release](#ساخت-apk-release)
7. [امضا و انتشار](#امضا-و-انتشار)
8. [پیکربندی Gradle (ایران)](#پیکربندی-gradle-ایران)
9. [adb — دستورات کاربردی](#adb--دستورات-کاربردی)
10. [عیب‌یابی](#عیب‌یابی)
11. [چک‌لیست](#چک‌لیست)

---

## پیش‌نیاز

| مورد | جزئیات |
|------|--------|
| Flutter SDK | `D:\Dev\flutter` (stable پویا) |
| Android SDK | `D:\Dev\Android\Sdk` |
| Java | Temurin 17 → `D:\Dev\Java\jdk-17` |
| NDK r27 | برای `flutter build apk --release` |
| SOCKS (ایران) | `127.0.0.1:10808` برای CDN/Gradle در صورت timeout |

```powershell
flutter doctor -v
# Android toolchain  →  ✓
```

---

## نصب toolchain (خلاصه)

از ریشه پروژه — **جزئیات کامل در [FLUTTER-SETUP-FA.md](FLUTTER-SETUP-FA.md)**:

```powershell
cd D:\0\calculator_app\calculator_app

powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-full-toolchain-d-drive.ps1
# یا مرحله‌به‌مرحله — FLUTTER-SETUP-FA.md
```

PowerShell جدید → `flutter doctor`

---

## اولین اجرا روی دستگاه

### 1) فعال‌سازی Developer options

روی گوشی Android:
**Settings → About phone →** ۷ بار tap روی **Build number**  
**Settings → Developer options → USB debugging** = ON

### 2) اتصال USB

```powershell
adb devices
# List of devices attached
# XXXXXXXX    device
```

اگر `unauthorized` — روی گوشی اجازه USB debugging را بپذیرید.

### 3) اجرا

```powershell
cd C:\Users\a_ra_80\Desktop\calculator_app
flutter devices
flutter run -d <device-id>
```

| کلید | عمل |
|------|-----|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | خروج |

---

## Emulator Android Studio

### ساخت AVD

1. Android Studio → **Device Manager**
2. **Create Device** → مثلاً Pixel 6
3. System Image: **API 34+** (برای compileSdk 36 کافی است؛ minSdk 27 روی emulator قدیمی‌تر هم OK)
4. Finish → ▶ Start

### اجرا روی emulator

```powershell
flutter devices
# emulator-5554
flutter run -d emulator-5554
```

### نکته عملکرد

- Emulator به **HAXM/WHPX** و RAM کافی نیاز دارد.
- برای تست سریع UI، **دستگاه فیزیکی** اغلب بهتر از emulator است.

---

## توسعه روزمره

### فایل‌های Android مهم

| فایل | نقش |
|------|-----|
| `android/app/build.gradle.kts` | `minSdk = 27`, NDK, signing |
| `android/settings.gradle.kts` | Maven mirrors (ایران) |
| `android/build.gradle.kts` | repositories |
| `android/app/src/main/AndroidManifest.xml` | label، activity |

### minSdk 27

```kotlin
// android/app/build.gradle.kts
defaultConfig {
    minSdk = 27   // Android 8.1+
    targetSdk = flutter.targetSdkVersion
}
```

نیازی به نصب `platforms/android-27` در SDK **نیست** — فقط compileSdk 36.

### تست

```powershell
flutter test          # روی host (بدون دستگاه)
flutter analyze
```

---

## ساخت APK Release

```powershell
cd C:\Users\a_ra_80\Desktop\calculator_app

# چک toolchain
powershell -ExecutionPolicy Bypass -File toolchain/scripts/verify-flutter-setup.ps1 -Strict -SkipDoctor

flutter build apk --release
```

| خروجی | مسیر |
|--------|------|
| APK | `build\app\outputs\flutter-apk\app-release.apk` |
| حجم تقریبی | ~۴۰–۴۵ MB (با NDK) |

### تأیید minSdk روی APK

```powershell
$aapt = "$env:LOCALAPPDATA\Android\Sdk\build-tools\34.0.0\aapt.exe"
& $aapt dump badging build\app\outputs\flutter-apk\app-release.apk | findstr sdkVersion
# sdkVersion:'27'
```

### نصب روی دستگاه

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

---

## امضا و انتشار

### Debug (فعلی پروژه)

`build.gradle.kts` از **debug signing** برای release استفاده می‌کند — فقط برای تست داخلی.

### Production (Play Store)

1. keystore بسازید:

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. `android/key.properties` (در git نگذارید):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. `android/app/build.gradle.kts` — `signingConfigs` release واقعی

4. **AAB** برای Play Store:

```powershell
flutter build appbundle --release
# build\app\outputs\bundle\release\app-release.aab
```

---

## پیکربندی Gradle (ایران)

نمونه کامل در همین repo — قبل از اولین APK در شبکه ایران:

| فایل | محتوا |
|------|--------|
| `android/settings.gradle.kts` | maven.myket.ir + Aliyun |
| `android/build.gradle.kts` | repositories |
| `android/gradle/wrapper/gradle-wrapper.properties` | Tencent Gradle 8.14 |
| `android/gradle.properties` | SOCKS JVM args |

کپی از قالب: `toolchain/templates/flutter-android-mirrors.snippet.kts`  
جزئیات: [FLUTTER-SETUP-FA.md — پیکربندی Gradle](FLUTTER-SETUP-FA.md#پیکربندی-gradle-هر-پروژه-apk)

---

## adb — دستورات کاربردی

```powershell
adb devices                    # لیست دستگاه‌ها
adb logcat                     # لاگ زنده (Ctrl+C)
adb install -r app-release.apk # نصب
adb uninstall com.example.calculator_app
adb shell pm list packages | findstr calculator
```

---

## عیب‌یابی

| خطا | راه‌حل |
|-----|--------|
| `Failed to find Build Tools 35.0.0` | `install-android-sdk-packages-iran.ps1` |
| `CMake 3.22.1 not found` | همان اسکریپت |
| `NDK not configured` | `-IncludeNdk` |
| Gradle timeout | SOCKS + Tencent mirror — [FLUTTER-SETUP-FA](FLUTTER-SETUP-FA.md) |
| `content-hash` pub | `PUB_HOSTED_URL=https://pub.myket.ir` |
| دستگاه دیده نمی‌شود | کابل USB، driver، `adb kill-server` سپس `adb start-server` |
| `INSTALL_FAILED_OLDER_SDK` | گوشی زیر Android 8.1 — minSdk 27 |

---

## چک‌لیست

- [ ] `verify-flutter-setup.ps1 -Strict` — صفر FAIL
- [ ] `flutter doctor` — Android ✓
- [ ] `minSdk = 27` در `build.gradle.kts`
- [ ] Gradle mirrors در `android/`
- [ ] `flutter run` روی دستگاه یا emulator
- [ ] `flutter build apk --release` موفق
- [ ] `aapt dump badging` → `sdkVersion:'27'`
- [ ] (production) keystore و AAB

---

**بازگشت به فهرست:** [README-FA.md](README-FA.md)  
**نصب عمیق toolchain:** [FLUTTER-SETUP-FA.md](FLUTTER-SETUP-FA.md)
