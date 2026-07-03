# راهنمای توسعه‌دهنده Web — calculator_app

> **مخاطب:** توسعه‌دهندگانی که Flutter را در **مرورگر** (Chrome/Edge) اجرا و deploy می‌کنند  
> **نیاز به Android SDK:** خیر (فقط Flutter + Chrome)  
> **راهنمای نصب toolchain:** [FLUTTER-SETUP-FA.md](FLUTTER-SETUP-FA.md) — بخش Flutter SDK و env کافی است

---

## فهرست

1. [پیش‌نیاز](#پیش‌نیاز)
2. [اولین اجرا](#اولین-اجرا)
3. [توسعه روزمره](#توسعه-روزمره)
4. [ساخت release وب](#ساخت-release-وب)
5. [Deploy استاتیک](#deploy-استاتیک)
6. [ساختار فایل‌های web](#ساختار-فایل‌های-web)
7. [عیب‌یابی](#عیب‌یابی)
8. [چک‌لیست](#چک‌لیست)

---

## پیش‌نیاز

| مورد | جزئیات |
|------|--------|
| Flutter SDK | [FLUTTER-SETUP-FA.md — نصب Flutter SDK](FLUTTER-SETUP-FA.md#نصب-flutter-sdk-یک‌بار-دستی) |
| مرورگر | Google Chrome یا Microsoft Edge (Chromium) |
| Pub mirror (ایران) | `PUB_HOSTED_URL=https://pub.myket.ir` |
| Web support | یک‌بار: `flutter config --enable-web` |

```powershell
flutter config --enable-web
flutter doctor
# بخش Chrome / Edge باید در دسترس باشد
```

---

## اولین اجرا

```powershell
cd C:\Users\a_ra_80\Desktop\calculator_app

$env:PUB_HOSTED_URL = "https://pub.myket.ir"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

flutter pub get
flutter test
flutter run -d chrome
```

- اولین build وب ممکن است ۱–۳ دقیقه طول بکشد.
- آدرس معمول: `http://localhost:<port>` — در ترمینال چاپ می‌شود.

### دستگاه‌های web

```powershell
flutter devices
# chrome — Google Chrome
# edge   — Microsoft Edge
# web-server — بدون UI مرورگر (headless server)
```

```powershell
flutter run -d edge          # Edge
flutter run -d web-server    # فقط سرور محلی
```

---

## توسعه روزمره

### Hot reload

| کلید | عمل |
|------|-----|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | خروج |

### ویرایش UI

- UI: `lib/main.dart` — Grid دکمه‌ها، تم Material 3 تیره
- منطق: `lib/calculator.dart` — تست‌پذیر، بدون `BuildContext`

```powershell
# فقط تست منطق (سریع)
flutter test test/calculator_test.dart

# smoke UI
flutter test test/widget_test.dart
```

### Responsive / اندازه صفحه

در Chrome: **F12 → Toggle device toolbar** — اندازه موبایل/تبلت را شبیه‌سازی کنید.  
Flutter Web همان `lib/main.dart` را رندر می‌کند؛ layout با `SafeArea` و `GridView` برای عرض‌های مختلف مناسب است.

---

## ساخت release وب

```powershell
cd C:\Users\a_ra_80\Desktop\calculator_app
flutter build web --release
```

| خروجی | مسیر |
|--------|------|
| فایل‌های استاتیک | `build\web\` |
| entry | `build\web\index.html` |
| JS/WASM | `build\web\main.dart.js` (یا wasm در نسخه‌های جدید) |

### پیش‌نمایش محلی (بعد از build)

```powershell
# Python 3
cd build\web
python -m http.server 8080
# مرورگر: http://localhost:8080
```

یا:

```powershell
flutter run -d web-server --release
```

### Base href (زیرمسیر deploy)

اگر سایت روی `https://example.com/apps/calc/` است:

```powershell
flutter build web --release --base-href /apps/calc/
```

---

## Deploy استاتیک

محتوای `build/web/` را روی هر **static host** بگذارید:

| سرویس | نکته |
|--------|------|
| **Nginx** | `root` → پوشه `build/web`؛ `try_files $uri /index.html` |
| **GitHub Pages** | `--base-href` مطابق نام repo |
| **Liara / Arvan / CDN** | آپلود کل `build/web` |
| **IIS** | MIME types برای `.wasm` و `.js` |

### نمونه Nginx

```nginx
server {
    listen 80;
    root /var/www/calculator_web;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### PWA

- `web/manifest.json` — نام، آیکون، theme
- برای آیکون: `web/icons/` (پیش‌فرض Flutter)
- Service worker: Flutter در release به‌صورت خودکار تولید می‌کند

---

## ساختار فایل‌های web

```
web/
  index.html      # base href، bootstrap
  manifest.json   # PWA metadata
  favicon.png
  icons/          # 192/512 برای PWA
```

فایل‌های build در git نیستند — همیشه `flutter build web` بگیرید.

---

## عیب‌یابی

### `flutter run -d chrome` دستگاه پیدا نمی‌کند

```powershell
flutter config --enable-web
flutter doctor -v
```

Chrome نصب باشد؛ مسیر در PATH یا registry Windows شناخته شود.

---

### `pub get` کند یا timeout

```powershell
$env:PUB_HOSTED_URL = "https://pub.myket.ir"
flutter pub get -v
```

راهنمای کامل: [FLUTTER-SETUP-FA.md — عیب‌یابی pub](FLUTTER-SETUP-FA.md#content-hash-در-pub-azsir)

---

### صفحه سفید بعد از deploy

- `--base-href` را با مسیر واقعی سرور هماهنگ کنید.
- Console مرورگر (F12) — خطای 404 برای `main.dart.js` یعنی base href اشتباه است.

---

### CORS / API (آینده)

این پروژه فعلاً **offline** است (بدون API). اگر backend اضافه کردید:
- در dev از proxy یا CORS سرور استفاده کنید.
- در production همان origin یا headerهای CORS صحیح.

---

## چک‌لیست

- [ ] `flutter config --enable-web`
- [ ] `PUB_HOSTED_URL` برای ایران
- [ ] `flutter pub get` بدون خطا
- [ ] `flutter test` — ۱۰/۱۰
- [ ] `flutter run -d chrome` — UI ماشین‌حساب باز می‌شود
- [ ] `flutter build web --release` — پوشه `build/web` ساخته شد
- [ ] (deploy) `--base-href` درست تنظیم شد

---

**بازگشت به فهرست:** [README-FA.md](README-FA.md)
