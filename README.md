# calculator_app · ماشین‌حساب

<p align="center">
  <strong>ماشین‌حساب استاندارد چندسکویی — Web · Windows · Android 8.1+</strong><br>
  <sub>Standard multi-platform calculator — production-ready · privacy-first · FA/EN</sub>
</p>

<p align="center">
  <code>v1.24.0+25</code> ·
  <code>275 automated tests</code> ·
  <code>Flutter 3.x</code> ·
  <code>minSdk 27</code> ·
  <code>no ads · no cloud</code>
</p>

---

## چرا این پروژه؟

| مزیت | توضیح |
|------|--------|
| **repeat `=`** | تکرار آخرین عملیات — قابلیتی که iOS 18 حذف کرد و کاربران Windows/Android انتظار دارند |
| **زنجیره LTR** | `2 + 3 × 4 = 20` — مثل Windows Calculator Standard (نه PEMDAS) |
| **بدون تبلیغ / بدون ابر** | همه داده‌ها روی دستگاه شما — مناسب بازار ایران و حریم خصوصی |
| **فارسی واقعی** | RTL · اعداد ۰–۹ · جداکننده اعشار ٫ · paste با ارقام فارسی |
| **دسکتاپ + موبایل** | تاریخچه کناری · میانبرهای کامل Windows · لمس + کیبورد |
| **تست صادقانه** | ۲۶۳+ تست واحد/ویجت + smoke CI — بدون shortcut تقلبی |

---

## قابلیت‌ها

### محاسبه و نمایش
- چهار عمل اصلی `+ − × ÷` · درصد · تغییر علامت · اعشار
- **Running total** — پیش‌نمایش جمع میانی هنگام تایپ (iOS 17 style)
- Expression line — نمایش `12 + 3` در حین ورود
- Repeat equals — فشار مجدد `=` همان عمل آخر را تکرار می‌کند
- Undo / Redo — `Ctrl+Z` / `Ctrl+Y`
- CE vs C — نگه‌داشتن `C` یا `Delete` فقط ورودی را پاک می‌کند
- خطای تقسیم بر صفر با بازیابی سریع

### حافظه (Memory)
- `M+` · `M−` · `MR` · `MC`
- میانبر Windows: `Ctrl+M/P/Q/R/L`
- بازخورد صوتی/بصری (Screen Reader + SnackBar)

### تاریخچه (History)
- ذخیره محاسبات · tap برای reuse · swipe برای حذف
- Export به clipboard (`Ctrl+Shift+H`)
- پاک کردن همه (`Ctrl+Shift+D`)
- پنل کناری در دسکتاپ (≥۹۰۰px) · bottom sheet در موبایل
- Dedupe — عبارت+نتیجه تکراری پشت سر هم ثبت نمی‌شود

### کپی / Paste
- Double-tap یا long-press روی display → منوی Copy/Paste
- `Ctrl+V` · `Shift+Insert` · paste چندخطی → **فقط خط اول**
- `Ctrl+Shift+C` — کپی عبارت در حال انتظار
- نرمال‌سازی ارقام فارسی و جداکننده هزارگان

### تنظیمات
| گزینه | کاربرد |
|--------|--------|
| تم (سیستم / روشن / تاریک) | Material 3 |
| زبان (English / فارسی) | RTL خودکار در FA |
| لرزش دکمه‌ها | Haptic feedback |
| نگه‌داشتن تاریخچه | Persist بعد از بستن |
| بازیابی جلسه | Display + pending op |
| اعداد فارسی ۰–۹ | نمایش و ورود |
| قفل لمس | Pocket mode — کیبورد فعال |
| پیش‌نمایش جمع تجمعی | Running total |

### دسترس‌پذیری (a11y)
- Semantics کامل keypad · display · history · memory
- پیمایش keypad با Arrow keys · Home / End
- Focus ring بعد از بستن settings/history
- WCAG touch target ≥ ۴۸dp

### Responsive
| Viewport | رفتار |
|----------|--------|
| 320px | compact phone |
| 390–667px | phone / landscape |
| 768–1024px | tablet |
| 1280–1920px | desktop + side history |

---

## پلتفرم‌ها و پیش‌نیاز

| پلتفرم | حداقل | Build |
|--------|--------|-------|
| **Web** | Chrome / Edge | `flutter build web --release` |
| **Windows** | Win 10/11 · VS Build Tools · **Developer Mode** (symlink) | `flutter build windows --release` |
| **Android** | 8.1 Oreo (API 27) | `flutter build apk --release` |

> **Windows:** اگر build با خطای symlink شکست خورد: Settings → Developer Mode → ON  
> `start ms-settings:developers`

---

## شروع سریع

```powershell
# از ریشه پروژه
cd path\to\calculator_app

# ایران — آینه Pub (اختیاری)
$env:PUB_HOSTED_URL = "https://pub.myket.ir"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

flutter pub get
flutter analyze
flutter test

# اجرا
flutter run -d chrome      # Web
flutter run -d windows     # Windows desktop
flutter run -d <device-id> # Android — flutter devices
```

### Smoke test (صادقانه — toolchain + app + build)

```powershell
powershell -ExecutionPolicy Bypass -File toolchain\tests\Run-SmokeTests.ps1
```

### تأیید toolchain

```powershell
powershell -ExecutionPolicy Bypass -File toolchain\scripts\verify-flutter-setup.ps1 -Strict
```

---

## میانبرهای کیبورد (Windows / Desktop)

| گروه | میانبرها |
|------|-----------|
| **پیمایش** | Arrow · Home/End · Space = activate focused key · Enter = equals · Esc = clear all |
| **ویرایش** | Ctrl+Z/Y · Ctrl+V · Shift+Insert · Backspace · Delete = CE |
| **حافظه** | Ctrl+M store · Ctrl+P add · Ctrl+Q subtract · Ctrl+R recall · Ctrl+L clear |
| **تاریخچه** | Ctrl+H panel · Ctrl+Shift+H export · Ctrl+Shift+D clear |
| **کپی** | Ctrl+Shift+C expression · long-press display = menu |
| **علامت** | F9 یا Shift+− |

> در اپ: دکمه ⌨ در app bar (دسکتاپ) یا **تنظیمات → میانبرهای کیبورد**

---

## ساخت Release

```powershell
flutter build web --release
flutter build apk --release
flutter build windows --release   # نیاز Developer Mode
```

خروجی‌ها:
- Web → `build/web/`
- APK → `build/app/outputs/flutter-apk/app-release.apk`
- Windows → `build/windows/x64/runner/Release/`

اسکریپت یک‌جا:

```powershell
powershell -ExecutionPolicy Bypass -File toolchain\scripts\run-production-builds.ps1
```

---

## معماری پروژه

```
lib/
├── main.dart                 # MaterialApp · locale · theme
├── calculator.dart           # موتور محاسبه (backend)
├── calc_history.dart         # تاریخچه in-memory + cap
├── settings/app_settings.dart
├── services/calc_persistence.dart
├── ui/
│   ├── calculator_page.dart  # orchestration · keyboard · lifecycle
│   ├── calc_layout.dart      # breakpoints responsive
│   ├── calc_rtl.dart         # RTL helpers
│   └── widgets/              # display · keypad · history · settings
├── utils/                    # digit_locale · paste_parser · display_format
└── l10n/                     # app_en.arb · app_fa.arb

test/                         # 275+ tests · round5–round23 QA suites
toolchain/                    # install scripts · smoke · docs FA
```

**جداسازی لایه‌ها:** `Calculator` (pure Dart) ← UI فقط state و رویداد — تست backend بدون widget ممکن است.

---

## تست

| دسته | پوشش |
|------|------|
| `calculator_test.dart` | backend · memory · paste · session |
| `responsive_widget_test.dart` | 320 → 1920px |
| `round5_qa` … `round22_qa` | نیازسنجی Windows/iOS/Android/FA |
| `Run-SmokeTests.ps1` | toolchain + analyze + test count + builds |

```powershell
flutter test                          # همه — باید 275 PASS
flutter test test/round23_qa_test.dart  # polish High bugs
flutter test test/round22_qa_test.dart  # RTL فارسی
```

---

## مستندات

| نقش | فایل |
|-----|------|
| **فهرست اصلی (FA)** | [toolchain/docs/README-FA.md](toolchain/docs/README-FA.md) |
| **Web** | [toolchain/docs/GUIDE-WEB-FA.md](toolchain/docs/GUIDE-WEB-FA.md) |
| **Windows** | [toolchain/docs/GUIDE-WINDOWS-FA.md](toolchain/docs/GUIDE-WINDOWS-FA.md) |
| **Mobile / APK** | [toolchain/docs/GUIDE-MOBILE-FA.md](toolchain/docs/GUIDE-MOBILE-FA.md) |
| **نصب Flutter (ایران)** | [toolchain/docs/FLUTTER-SETUP-FA.md](toolchain/docs/FLUTTER-SETUP-FA.md) |
| **نیازسنجی ۲۰ دور QA** | [toolchain/docs/CALCULATOR-NEEDS-AUDIT-FA.md](toolchain/docs/CALCULATOR-NEEDS-AUDIT-FA.md) |
| **اسکریپت‌های toolchain** | [toolchain/README.md](toolchain/README.md) |

---

## حریم خصوصی

- **هیچ داده‌ای** به سرور ارسال نمی‌شود
- **بدون تبلیغ** · **بدون analytics اجباری** · **بدون حساب کاربری**
- تاریخچه و تنظیمات فقط در `SharedPreferences` روی دستگاه

---

## نسخه‌گذاری

| نسخه | build | یادداشت |
|------|-------|---------|
| **1.24.0** | 25 | Paste locale · loadResult · touch lock · % ×/÷ · FA digits toggle |
| **1.23.0** | 24 | RTL فارسی · مودال میانبرها · settings dialog |
| 1.20.0 | 21 | multiline paste · Shift+Insert · display menu |
| 1.15+ | 16+ | ۲۰ دور QA · 170+ نیاز رفع‌شده |

فرمت: `major.minor.patch+buildNumber` در `pubspec.yaml`

---

## مشارکت و QA

1. `flutter analyze` باید clean باشد  
2. `flutter test` — همه PASS  
3. برای تغییر UI: تست viewport 320 و 1280  
4. برای FA: `locale: Locale('fa')` در widget tests  
5. smoke قبل از release: `Run-SmokeTests.ps1`

---

## English summary

**calculator_app** is a privacy-first, ad-free standard calculator built with Flutter for Web, Windows, and Android 8.1+. It follows Windows Standard left-to-right chaining (not PEMDAS), supports full Persian RTL UI, persistent history, memory, undo/redo, keyboard shortcuts, and 275 automated tests. See `toolchain/docs/` for platform-specific guides.

---

<p align="center">
  <sub>Built with Flutter · Tested honestly · No cloud · No ads</sub>
</p>
