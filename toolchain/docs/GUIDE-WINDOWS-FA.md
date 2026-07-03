# راهنمای توسعه‌دهنده Windows — calculator_app

> **مخاطب:** توسعه‌دهندگانی که اپ **دسکتاپ Windows** (exe) می‌سازند  
> **نیاز به Android SDK:** خیر  
> **پیش‌نیاز اصلی:** Flutter SDK + Visual Studio (Desktop C++)

---

## فهرست

1. [پیش‌نیاز](#پیش‌نیاز)
2. [نصب Visual Studio](#نصب-visual-studio)
3. [اولین اجرا](#اولین-اجرا)
4. [توسعه روزمره](#توسعه-روزمره)
5. [Build Release و توزیع](#build-release-و-توزیع)
6. [ساختار پروژه Windows](#ساختار-پروژه-windows)
7. [عیب‌یابی](#عیب‌یابی)
8. [چک‌لیست](#چک‌لیست)

---

## پیش‌نیاز

| مورد | جزئیات |
|------|--------|
| Flutter SDK | [FLUTTER-SETUP-FA.md](FLUTTER-SETUP-FA.md#نصب-flutter-sdk-یک‌بار-دستی) |
| Windows 10/11 | 64-bit |
| Visual Studio 2019 یا 2022 | workload زیر |
| Pub mirror (ایران) | `PUB_HOSTED_URL=https://pub.myket.ir` |

```powershell
flutter doctor -v
# Visual Studio - develop Windows apps  →  باید ✓ باشد
```

---

## نصب Visual Studio

### روش خودکار (توصیه — D: drive، دانلود لایه‌ای)

از **PowerShell با دسترسی Administrator** (نصب VS ~10–40 دقیقه):

```powershell
cd D:\0\calculator_app\calculator_app

# فقط Windows desktop toolchain
powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-windows-desktop-toolchain.ps1

# یا همراه همه toolchain
powershell -ExecutionPolicy Bypass -File toolchain/scripts/install-full-toolchain-d-drive.ps1
```

نصب پیش‌فرض: `D:\Dev\VS2022BuildTools` — شامل **MSVC**، **CMake** (داخل VS)، **Windows 11 SDK** (22621 و/یا 26100).

ترتیب دانلود bootstrapper: `aka.ms` (Microsoft) → SOCKS → در صورت نیاز CMake standalone از GitHub/cmake.org → آینه ایران (`wget.s13est.com`).

### روش دستی (fallback)

1. [Visual Studio Community](https://visualstudio.microsoft.com/) را نصب کنید.
2. در **Workloads** این گزینه را فعال کنید:

   **Desktop development with C++**

3. در جزئیات (Optional) مطمئن شوید:
   - MSVC v142/v143 C++ build tools
   - Windows 10/11 SDK
   - C++ CMake tools for Windows

4. PowerShell **جدید** باز کنید:

```powershell
flutter doctor
```

---

## اولین اجرا

```powershell
cd C:\Users\a_ra_80\Desktop\calculator_app

$env:PUB_HOSTED_URL = "https://pub.myket.ir"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

flutter pub get
flutter test
flutter run -d windows
```

- اولین build ممکن است **۳۰–۶۰ ثانیه** (یا بیشتر) طول بکشد — CMake + MSVC.
- پنجره native Windows با عنوان **Calculator** باز می‌شود.

---

## توسعه روزمره

### Hot reload

| کلید | عمل |
|------|-----|
| `r` | Hot reload — UI سریع |
| `R` | Hot restart |
| `d` | Detach — exe باز بماند، flutter run بسته شود |
| `q` | بستن اپ |

### فایل‌های مهم

| فایل | نقش |
|------|-----|
| `lib/main.dart` | UI اصلی |
| `lib/calculator.dart` | منطق |
| `windows/runner/main.cpp` | entry point بومی |
| `windows/runner/Runner.rc` | آیکون، metadata exe |

### تست قبل از commit

```powershell
flutter test
flutter analyze
```

---

## Build Release و توزیع

### Debug (توسعه)

```powershell
flutter run -d windows
# خروجی: build\windows\x64\runner\Debug\calculator_app.exe
```

### Release (توزیع)

```powershell
flutter build windows --release
```

| فایل/پوشه | مسیر |
|-----------|------|
| exe اصلی | `build\windows\x64\runner\Release\calculator_app.exe` |
| DLLها و data | همان پوشه `Release\` (همه را با هم کپی کنید) |

```powershell
# اجرای مستقیم
.\build\windows\x64\runner\Release\calculator_app.exe
```

### توزیع به کاربر نهایی

کل محتوای پوشه **`Release`** را zip کنید — فقط exe کافی نیست:

```
Release/
  calculator_app.exe
  flutter_windows.dll
  data/
  ... (سایر dllها)
```

کاربر نیازی به نصب Flutter ندارد — فقط extract و اجرای exe.

### نسخه و نام محصول

در `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

برای build با نسخه سفارشی:

```powershell
flutter build windows --release --build-name=1.0.0 --build-number=1
```

---

## ساختار پروژه Windows

```
windows/
  CMakeLists.txt
  runner/
    main.cpp           # Win32 entry
    flutter_window.cpp
    resources/app_icon.ico
  flutter/             # generated glue
```

Build artifacts در `build/windows/` — در git ignore است.

---

## عیب‌یابی

### `flutter doctor` — Visual Studio زرد/قرمز

- workload **Desktop development with C++** نصب نیست → Visual Studio Installer → Modify
- بعد از نصب، **ترمینال جدید** و `flutter doctor` مجدد

---

### خطای CMake / MSB8066

```powershell
flutter clean
flutter pub get
flutter run -d windows -v
```

لاگ `-v` را برای خطای دقیق MSVC بخوانید.

---

### `LNK1104` یا missing DLL

Release را از **کل پوشه Release** اجرا کنید، نه فقط exe کپی‌شده.

---

### build کند

- اولین build طبیعی است؛ بعدی‌ها incremental سریع‌ترند.
- آنتی‌ویروس گاهی `build/` را کند می‌کند — استثنا اضافه کنید.

---

### Pub/network (ایران)

```powershell
$env:PUB_HOSTED_URL = "https://pub.myket.ir"
flutter pub get
```

---

## چک‌لیست

- [ ] Visual Studio + workload C++ desktop
- [ ] `flutter doctor` — Windows ✓
- [ ] `flutter test` — ۱۰/۱۰
- [ ] `flutter run -d windows` — پنجره باز می‌شود
- [ ] Hot reload (`r`) کار می‌کند
- [ ] `flutter build windows --release` — exe در Release
- [ ] zip کل پوشه Release برای توزیع

---

**بازگشت به فهرست:** [README-FA.md](README-FA.md)  
**نصب toolchain ایران:** [FLUTTER-SETUP-FA.md](FLUTTER-SETUP-FA.md)
