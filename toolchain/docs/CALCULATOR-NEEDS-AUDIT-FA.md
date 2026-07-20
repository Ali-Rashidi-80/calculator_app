# نیازسنجی جامع ماشین‌حساب | calculator_app

**تاریخ:** ۲۰ ژوئیه ۲۰۲۶ (به‌روز: v1.24 — دور بیست‌وسوم: paste locale + loadResult + touch lock + % ×/÷)  
**منابع:** GitHub microsoft/calculator (#1810, #1947, #2448, #2396, #162), Pearson keypad a11y, WCAG 2.1, iOS 18, بازار/مایکت  
**هدف:** فهرست اتمیک ایرادات، بهبودها و نیازمندی‌ها برای اپ Flutter فعلی

---

## ۱. خلاصه اجرایی

| وضعیت | تعداد |
|-------|-------|
| **رفع‌شده تا v1.24** | ۱۸۲+ مورد |
| **P0 — باید باشد** | ۱۲ مورد — **همه ✅** |
| **P1 — بهبود مهم** | ۳۰ مورد — **همه ✅** |
| **P2 — آینده / scientific** | ۱۰ مورد |

اپ فعلی **ماشین‌حساب استاندارد production-ready** با responsive کامل، **۲۷۵ تست**، smoke CI و پوشش viewport 320→1920px.

### مزیت رقابتی نسبت به iOS 18 / اپ‌های ایرانی
- ✅ **repeat `=`** (iOS 18 حذف کرد — شکایت گسترده)
- ✅ **بدون تبلیغ** (شکایت #۱ مایکت/بازار)
- ✅ **backspace واضح** + CE
- ✅ **AC واقعاً session را پاک می‌کند** (باگ iOS 18 #255793974)
- ✅ **PEMDAS vs LTR** مستند شده (شکایت Samsung `50+50×2=150`)

---

## ۲. Windows 10/11 Calculator — مشکلات گزارش‌شده

### ۲.۱ پایداری و چند پنجره (GitHub #2358, #2386)

| مشکل | جزئیات | اقدام برای اپ Flutter |
|------|--------|------------------------|
| Restore از taskbar → پنجره دوم | نسخه 11.2502+ Win11 | **تک‌instance:** `window_manager` / جلوگیری از اجرای duplicate exe |
| پنجره frozen بعد از minimize | دکمه‌ها بی‌پاسخ | تست smoke روی Windows restore/minimize |
| Crash در Scientific mode | محاسبات سنگین | N/A (فعلاً scientific نداریم) |
| Crash با History باز | expand window | اگر history اضافه شد → lazy load + pagination |

### ۲.۲ UI و ریسایز (#2269, #2290)

| مشکل | جزئیات | اقدام |
|------|--------|--------|
| فاصله نامتقارن دکمه‌ها بعد از resize | 4K، misalign 8/9 | **Layout ثابت:** `Expanded` + aspect ratio؛ تست golden چند breakpoint |
| 1px rounding در keypad | ستون boundary | padding یکسان (۵px در calc_button) — OK |
| Fixed size mode | کاربر نمی‌تواند resize | Windows: min size معقول؛ max width card |

### ۲.۳ رفتار محاسباتی Windows

| رفتار | انتظار کاربر | وضعیت اپ |
|-------|--------------|----------|
| زنجیره چپ‌به‌راست | `2+3×4=20` نه PEMDAS | ✅ پیاده |
| تکرار `=` | آخرین عمل تکرار شود | ✅ v1.1 |
| Memory (M+, MR…) | در Standard | ✅ v1.2 |
| History tape | ستون چپ در wide | ✅ v1.1 |
| History پایدار | بعد از بستن (#2392) | ✅ v1.2 |
| CE vs C | long-press C | ✅ v1.2 |
| Copy result | کلیک راست / Ctrl+C | ✅ |
| Paste | Ctrl+V | ✅ v1.2 |
| **% در زنجیره** | `50+10%` → 55 (Windows Standard) | ✅ v1.12 |
| **Undo/Redo** | Ctrl+Z / Ctrl+Y (Kalkyl-style) | ✅ v1.12 |

---

## ۳. موبایل (Android / iOS) — انتقادات UX

### ۳.۱ iOS (9to5Google, Medium case study)

| شکایت | راه‌حل پیشنهادی | اولویت |
|-------|-----------------|--------|
| operand اول بعد از شروع رقم دوم **ناپدید** می‌شود | نمایش `12 + 3` در expression | ✅ **رفع شد** |
| **بدون history** | tape + scroll | ✅ v1.1 |
| swipe delete history | حذف تکی | ✅ v1.2 |
| tap history → reuse | نتیجه در display | ✅ v1.2 |
| backspace **مخفی** (swipe) | دکمه ⌫ واضح | ✅ داریم |
| پاک کردن کل خط به‌جای یک رقم | deleteLast + backspace | ✅ داریم |
| gesture stuck key | debounce tap | ✅ v1.2 (≠ روی `=`) |

### ۳.2 Android / Google Calculator

| شکایت | راه‌حل | اولویت |
|-------|--------|--------|
| History با swipe down | persistent column در tablet | P1 |
| چرخش → scientific | rotate یا tab | P2 |
| کسری ↔ اعشار | تبدیل format | P2 |

### ۳.۳ کاربران فارسی (بازار، مایکت، دیجی‌کالا مگ)

| نیاز | بازخورد واقعی | اولویت |
|------|---------------|--------|
| **بدون تبلیغ** | شکایت اصلی اپ‌های ایرانی | ✅ ما ad-free |
| **ممیز کار نکند** | گزارش در «ماشین‌حساب فارسی» | تست `,` و `.` — ✅ keyboard |
| تم روز/شب | انتظار رایج | ✅ v1.1 |
| اعداد فارسی ۰–۹ | اختیاری | ✅ v1.1 + **٫ اعشار v1.13** |
| لرزش/صدا قابل تنظیم | شخصی‌سازی | ✅ v1.2 (toggle haptics) |
| **دقت محاسبات** | مهم‌ترین praise | ✅ + format + sci notation |

### ۳.۴ Forum / regression بعد از update

| ریسک | پیشگیری |
|------|---------|
| موتور محاسبه خراب بعد از refactor | 55+ تست؛ CI smoke |
| localization اشتباه (`,` vs `.`) | هر دو در keyboard |
| operator precedence اشتباه | document: chained LTR |

---

## ۴. دسترس‌پذیری (WCAG 2.1 AA, Pearson, A11yPath)

| معیار | الزام | وضعیت قبل | بعد |
|-------|-------|-----------|-----|
| **4.1.3 Status Messages** | اعلان خطا/نتیجه به SR | ❌ | ✅ `Semantics` live region |
| **4.1.2 Name, Role, Value** | label دکمه‌ها | ⚠️ نماد خام | ✅ label + **disabled state v1.13** |
| **2.5.5 Target Size** | ≥24×24 CSS px | ✅ ~48dp | OK |
| **1.4.3 Contrast** | 4.5:1 متن | ✅ dark theme | تست light |
| Keyboard همه controls | Tab + shortcuts | ✅ desktop | ✅ v1.7 arrows |
| **Focus visible** | outline | Material default | ✅ v1.7 keypad ring |
| High Contrast Windows | visible در HC mode | تست دستی | P1 |

---

## ۵. دقت عددی و edge cases

| مورد | مشکل شناخته‌شده | راه‌حل صنعتی | وضعیت اپ |
|------|-----------------|--------------|----------|
| `0.1 + 0.2` | `0.30000000000000004` | BCD / rational (Desmos) | `_format` تا 8 رقم — نمایش `0.3` |
| تقسیم بر صفر در `=` | error message | ✅ | ✅ |
| تقسیم بر صفر در زنجیره `8÷0+` | **uncaught throw** | catch در logic+UI | ✅ **رفع شد** |
| overflow display | بی‌نهایت رقم | max 16 digit | ✅ **رفع شد** |
| `0.` + equals | parse fail silent | ✅ `_parseDisplay` → 0 |
| double `-` sign | `--5` | toggleSign | OK |
| percent در chain | `50+10%` → 55 | Windows Standard accumulator % | ✅ v1.12 |
| PEMDAS expectation | کاربر انتظار دارد | **LTR chained** — در UI بنویسید | P1 tooltip |

---

## ۶. ماتریس نیازمندی — P0 (باید)

| ID | نیازمندی | منبع | وضعیت |
|----|----------|------|--------|
| R-01 | تقسیم بر صفر safe در همه مسیرها | HN, unit test gap | ✅ v1.0 |
| R-02 | نمایش عبارن کامل `a op b` | 9to5Google, iOS UX | ✅ v1.0 |
| R-03 | backspace واضح | iOS critique | ✅ |
| R-04 | keyboard desktop کامل | Pearson | ✅ |
| R-05 | announce نتیجه/خطا برای SR | WCAG 4.1.3 | ✅ |
| R-06 | semantic label دکمه‌ها | Pearson | ✅ |
| R-07 | محدودیت طول ورودی | overflow UX | ✅ |
| R-08 | copy نتیجه | Windows calc | ✅ |
| R-09 | haptic feedback موبایل | Persian apps | ✅ |
| R-10 | بدون تبلیغ | مایکت reviews | ✅ |
| R-11 | تست regression محاسبات | forum | ✅ 101 tests |
| R-12 | minSdk 27 / Win10+ | پروژه | ✅ |

---

## ۷. P1 — بهبود مهم

| ID | نیازمندی | توضیح | وضعیت |
|----|----------|--------|--------|
| P1-01 | History tape | ستون چپ ≥900px؛ bottom sheet موبایل | ✅ v1.1 |
| P1-02 | تم روشن + system | `ThemeMode` + ذخیره | ✅ v1.1 |
| P1-03 | localization FA/EN | `flutter gen-l10n` | ✅ v1.1 |
| P1-04 | تکرار `=` | last op + operand (Windows) | ✅ v1.1 |
| P1-05 | operator swap visual | highlight pending op | ✅ v1.1 |
| P1-06 | Windows single instance | جلوگیری duplicate | ✅ v1.6 |
| P1-07 | golden tests UI | resize breakpoints | ⏳ P2 |
| P1-08 | `package:decimal` | دقت مالی | ⏳ P2 |
| P1-09 | راهنمای PEMDAS vs chained | tooltip / about | ✅ v1.1 (تنظیمات) |
| P1-10 | Android label = Calculator | manifest | ✅ v1.1 |
| P1-11 | PWA manifest polish | web | ✅ v1.1 |
| P1-12 | debounce rapid tap | stuck key iOS-like | ✅ v1.2 |
| P1-13 | History persistence | #2392 Windows | ✅ v1.2 |
| P1-14 | CE (clear entry) | long-press C | ✅ v1.2 |
| P1-15 | Memory M+/MR/MC | Windows Standard | ✅ v1.2 |
| P1-16 | Paste Ctrl+V | desktop UX | ✅ v1.2 |
| P1-17 | History tap reuse | Android/iOS | ✅ v1.2 |
| P1-18 | Swipe delete history item | mobile pattern | ✅ v1.2 |
| P1-19 | Session restore | display + pending | ✅ v1.2 |
| P1-20 | Scientific notation display | overflow UX | ✅ v1.2 |
| P1-21 | Haptics toggle | Persian prefs | ✅ v1.2 |
| P1-22 | M− memory subtract | Windows Standard | ✅ v1.3 |
| P1-23 | Persian digits ۰–۹ | بازار/FA users | ✅ v1.3 |
| P1-24 | Arabic decimal ٫ paste | FA locale | ✅ v1.3 |
| P1-25 | restoreSession toggle | iOS 18 stale bug | ✅ v1.3 |
| P1-26 | Swipe-down history | Google Calc gesture | ✅ v1.3 |
| P1-27 | Expression horizontal scroll | iOS 18 long expr | ✅ v1.3 |
| P1-28 | Snapshot validation | GitHub #2458 | ✅ v1.3 |
| P1-29 | Esc announce cleared | WCAG Pearson | ✅ v1.3 |
| P1-30 | Privacy / no-ads note | مایکت reviews | ✅ v1.3 |
| P1-31 | Responsive CalcLayout | Material breakpoints | ✅ v1.4 |
| P1-32 | 48dp touch targets | WCAG 2.5.5 | ✅ v1.4 |
| P1-33 | Viewport tests 320–1920 | honest QA | ✅ v1.4 |
| P1-34 | Error clear persists session | iOS 18 bug | ✅ v1.4 |
| P1-35 | Full flow integration test | E2E backend | ✅ v1.4 |
| P1-36 | Windows memory shortcuts | Ctrl+M/P/Q/R/L | ✅ v1.8 |
| P1-37 | Delete=CE · F9=± | Windows Standard | ✅ v1.8 |
| P1-38 | Resume refocus keyboard | #2118 / #2448 | ✅ v1.8 |
| P1-39 | exportSession always valid | #2458 | ✅ v1.8 |

---

## ۸. P2 — آینده

- Scientific / Programmer mode  
- Unit conversion / currency  
- Graphing  
- iOS native project  
- Widget home screen  
- Wear OS  
- Sync history cloud (Google sync)  
- Windows single instance (`window_manager`) — ✅ v1.6 native mutex
- golden tests UI — #2182 scaling  
- `package:decimal` برای مالی  
- Arrow-key keypad navigation — ✅ v1.7 Pearson grid
- Touch lock / pocket mode — ✅ v1.7 settings toggle
- Running total column — iOS 18 removed feature — ✅ v1.10 live preview
- High Contrast Windows theme test — ✅ v1.10 keypad borders

---

## ۹. چک‌لیست QA دستی (پس از هر release)

```
[ ] 2+3×4=20 (chained LTR)
[ ] 8÷0= → error, recovery با digit
[ ] 8÷0+ → error (chain)
[ ] 0.1+0.2=0.3 (display)
[ ] 16+ digit → reject input
[ ] Backspace بعد از op → no-op
[ ] Keyboard: *, /, numpad, ,
[ ] Ctrl+C copy result (desktop)
[ ] Ctrl+V paste number (desktop)
[ ] Long-press C → CE (entry only)
[ ] M+ / MR / MC memory bar
[ ] History tap → reuse result
[ ] History swipe → delete item
[ ] Close app → reopen → history + session restored
[ ] Long-press copy (mobile)
[ ] TalkBack/VoiceOver: دکمه «تقسیم» نه «÷»
[ ] Windows minimize/restore
[ ] APK arm64 minSdk 27 device
[ ] flutter test — all pass
```

---

## ۱۰. منابع

- https://github.com/microsoft/calculator/issues/2275,2358,2386,2269,2392,2474  
- https://9to5google.com/2024/01/26/calculating-calculator-critiques-android-iphone/  
- https://news.ycombinator.com/item?id=42810300  
- https://engineering.desmos.com/articles/intuitive-calculator-arithmetic/  
- https://accessibility.pearson.com/resources/developers-corner/reference-library/calculator/  
- https://www.digikala.com/mag/9-best-free-calculator-apps-for-android/  
- https://cafebazaar.ir/app/ir.rahroteam.calculator  

---

## ۱۱. تغییرات اعمال‌شده

### v1.0 — audit P0
| فایل | تغییر |
|------|-------|
| `lib/calculator.dart` | expression کامل؛ max digits؛ div-zero در chain |
| `lib/ui/calculator_page.dart` | catch error؛ Ctrl+C |
| `lib/ui/widgets/calc_display_panel.dart` | Semantics live؛ long-press copy |
| `lib/ui/widgets/calc_keypad.dart` | semantic hints |

### v1.1 — P1 features
| فایل | تغییر |
|------|-------|
| `lib/calc_history.dart` | tape تا ۱۰۰ سطر |
| `lib/calculator.dart` | repeat `=`؛ history؛ `pendingOp` |
| `lib/l10n/app_en.arb`, `app_fa.arb` | FA/EN |
| `lib/settings/app_settings.dart` | تم + زبان (SharedPreferences) |
| `lib/theme/app_theme.dart` | light + dark |
| `lib/ui/widgets/calc_history_panel.dart` | پنل تاریخچه |
| `lib/ui/widgets/calc_settings_sheet.dart` | تنظیمات + about PEMDAS |
| `lib/ui/widgets/calc_keypad.dart` | highlight عملگر فعال |
| `android/.../AndroidManifest.xml` | label Calculator |
| `web/manifest.json` | PWA polish |

**تست‌ها:** 47 PASS · `flutter analyze` clean

### v1.2 — دور دوم (persistence, memory, CE, paste)
| فایل | تغییر |
|------|-------|
| `lib/services/calc_persistence.dart` | history + session + memory در SharedPreferences |
| `lib/models/calc_history_entry.dart` | id + JSON |
| `lib/calc_history.dart` | loadEntries, removeById |
| `lib/calculator.dart` | CE, memory, paste, sci notation, session export/restore |
| `lib/ui/calculator_page.dart` | persistence lifecycle, paste, history reuse/delete |
| `lib/ui/widgets/calc_memory_bar.dart` | M+/MR/MC |
| `lib/ui/widgets/calc_history_panel.dart` | Dismissible + tap reuse |
| `lib/ui/widgets/calc_button.dart` | debounce (≠ `=`), long-press, haptics toggle |
| `lib/ui/widgets/calc_keypad.dart` | long-press C → CE |
| `lib/ui/widgets/calc_settings_sheet.dart` | haptics + persist history toggles |
| `lib/settings/app_settings.dart` | hapticsEnabled, persistHistory |
| `lib/l10n/app_*.arb` | CE, memory, paste strings |

**تست‌ها:** 55 PASS · `flutter analyze` clean

### v1.3 — دور سوم (FA digits, M−, iOS18 fixes, validation)
| فایل | تغییر |
|------|-------|
| `lib/utils/digit_locale.dart` | ارقام فارسی/عربی + ممیز ٫ |
| `lib/calculator.dart` | M−، ورودی فارسی |
| `lib/services/calc_persistence.dart` | اعتبارسنجی snapshot (#2458) |
| `lib/settings/app_settings.dart` | restoreSession، persianDigits |
| `lib/ui/widgets/calc_display_panel.dart` | scroll افقی + swipe history |
| `lib/ui/widgets/calc_memory_bar.dart` | M− |
| `lib/ui/calculator_page.dart` | announce Esc، toggle session |
| `test/digit_locale_test.dart` | 3 تست |
| `test/calc_persistence_test.dart` | 2 تست |

**تست‌ها:** 64 PASS · `flutter analyze` clean

### v1.4 — دور چهارم (responsive polish + 101 tests)
| فایل | تغییر |
|------|-------|
| `lib/ui/calc_layout.dart` | breakpoints 320/360/600/840/900/1280 |
| `lib/ui/calculator_page.dart` | CalcLayout integration |
| `lib/ui/widgets/calc_button.dart` | 48dp min touch + responsive font |
| `lib/settings/app_settings.dart` | FA locale → Persian digits auto |
| `test/calc_layout_test.dart` | 5 breakpoint unit tests |
| `test/calc_history_test.dart` | 7 history tests |
| `test/calculator_full_flow_test.dart` | full session E2E |
| `test/responsive_widget_test.dart` | 7 viewport widget tests |
| `test/widget_features_test.dart` | memory, CE, FA, settings |
| `test/test_helpers.dart` | shared honest pump helpers |
| `test/calc_persistence_test.dart` | expanded to 5 tests |

**تست‌ها:** 101 PASS · smoke CI · `flutter analyze` clean

### v1.5 — دور پنجم (focus reliability + lifecycle QA + edge matrix)
| فایل | تغییر |
|------|-------|
| `lib/ui/calc_layout.dart` | `isLandscapePhone`، ارتفاع فشرده landscape، فونت دکمه |
| `lib/ui/calculator_page.dart` | `_refocusKeyboard()` پس از history/settings/load |
| `test/round5_qa_test.dart` | 8 تست صادقانه: focus، persistence relaunch، side history |
| `test/calculator_edge_cases_test.dart` | 8 تست ماتریس backend |
| `test/test_helpers.dart` | `relaunchCalculatorApp`، `dismissBottomSheet`، `preservePrefs` |
| `test/calc_layout_test.dart` | landscape phone compact height |

**تست‌ها:** 118 PASS · smoke CI 21/21 · `flutter analyze` clean

### v1.6 — دور ششم (swipe-delete, numpad, Windows single-instance, validation)
| فایل | تغییر |
|------|-------|
| `lib/ui/widgets/calc_display_panel.dart` | swipe-left → backspace (iOS 18 UX) |
| `lib/ui/calculator_page.dart` | numpad ±×÷ · announce نتیجه پس از `=` |
| `lib/services/calc_persistence.dart` | invariant: lastOp↔lastOperand، pendingOp↔accumulator |
| `windows/runner/main.cpp` | single-instance mutex (#2386) |
| `windows/runner/win32_window.cpp` | min window 320×480 |
| `lib/l10n/app_*.arb` | swipe-left hint · numpad در keyboardHint |
| `test/round6_qa_test.dart` | swipe، numpad، repeat= |
| `test/calc_persistence_test.dart` | +2 validation tests |

**تست‌ها:** 125 PASS · smoke CI · `flutter analyze` clean

### v1.7 — دور هفتم (Pearson arrow grid + touch lock + error announce)
| فایل | تغییر |
|------|-------|
| `lib/ui/calc_keypad_grid.dart` | ناوبری ۵×۴ Home/End/Arrows |
| `lib/ui/calculator_page.dart` | Space فعال‌سازی · announce خطا |
| `lib/ui/widgets/calc_button.dart` | `keyboardFocused` ring · touch lock |
| `lib/ui/widgets/calc_keypad.dart` | focus id + touch block hint |
| `lib/settings/app_settings.dart` | `touchLock` persisted |
| `lib/ui/widgets/calc_settings_sheet.dart` | toggle قفل لمس |
| `test/calc_keypad_grid_test.dart` | 6 unit tests |
| `test/round7_qa_test.dart` | 5 widget tests |

**تست‌ها:** 136 PASS · smoke CI · `flutter analyze` clean

### v1.8 — دور هشتم (Windows shortcuts + lifecycle + export invariants)
| فایل | تغییر |
|------|-------|
| `lib/calculator.dart` | `memoryStore()` برای Ctrl+M |
| `lib/ui/calculator_page.dart` | Ctrl+M/P/Q/R/L · Ctrl+H · Delete=CE · F9 · resume refocus |
| `lib/l10n/app_*.arb` | memory shortcuts در hint · Delete=CE |
| `test/round8_qa_test.dart` | 7 تests shortcuts + lifecycle + export |

**تست‌ها:** 136 PASS · smoke CI · `flutter analyze` clean

### v1.15 — دور پانزدهم (memory persist + Persian loadResult + Ctrl+Shift+D)
| فایل | تغییر |
|------|-------|
| `lib/calculator.dart` | `parseNumericText()` · `loadResult()` locale · `exportHistoryText()` ASCII |
| `lib/ui/calculator_page.dart` | memory when session off (#2315) · Ctrl+Shift+D · SR announce clear/delete |
| `lib/l10n/app_*.arb` | `historyCleared` · `historyItemDeleted` · keyboardHint |
| `test/round15_qa_test.dart` | 7 tests Persian/load/memory/history |

**تست‌ها:** 219 PASS · smoke 21/21 · `flutter analyze` clean

---

### v1.24 — دور بیست‌وسوم (paste locale + loadResult + touch lock + % ×/÷)
| فایل | تغییر |
|------|-------|
| `lib/utils/digit_locale.dart` | EU/US dual-separator paste (`1.234,56` / `1,234.56`) |
| `lib/utils/paste_parser.dart` | normalize قبل از allowlist · per-token در expression |
| `lib/calculator.dart` | loadResult clears `_lastOp` · % ×/÷ = value/100 |
| `lib/settings/app_settings.dart` | usePersianDigits مستقل · FA switch-in defaults ON |
| `lib/ui/widgets/calc_display_panel.dart` | touch lock روی gestures |
| `lib/ui/widgets/calc_memory_bar.dart` | touch lock روی M+/MR |
| `lib/ui/calculator_page.dart` | dispose-safe `_persist` · %/MR catch · Space docs |
| `test/round23_qa_test.dart` | 12 honest High tests |

**تست‌ها:** 275 PASS · `flutter analyze` (info-only curly braces pre-existing) · format clean

---

## ۳۰. ماتریس دور بیست‌وسوم — Final Polish High

| ID | نیاز | منبع | v1.24 |
|----|------|------|------|
| R23-01 | Paste EU/US comma/dot | MS #2396 | ✅ |
| R23-02 | loadResult clears equals-repeat | history reuse | ✅ |
| R23-03 | touch lock display+memory | pocket mode | ✅ |
| R23-04 | Space ≠ equals docs | honest UX | ✅ |
| R23-05 | % ×/÷ Windows Standard | Win calc | ✅ |
| R23-06 | FA digits toggle OFF | settings | ✅ |
| R23-07 | dispose/_persist snapshot | lifecycle | ✅ |
| R23-08 | %/MR error catch | overflow safety | ✅ |
| R23-09 | 275 honest tests | user request | ✅ |

---

### v1.20 — دور بیستم (multiline paste + display menu + Shift+Insert)
| فایل | تغییر |
|------|-------|
| `lib/utils/paste_parser.dart` | first-line multiline paste (NerdCalci #193) |
| `lib/ui/widgets/calc_display_panel.dart` | long-press/right-click copy/paste menu |
| `lib/ui/calculator_page.dart` | Shift+Insert · memory/equals hints |
| `lib/l10n/app_*.arb` | copyAction · pasteAction · nothingInMemory · noEqualsPending |
| `test/round20_qa_test.dart` | 7 tests paste/menu/keyboard |

**تست‌ها:** 254 PASS · smoke 21/21 · `flutter analyze` clean

---

## ۲۹. ماتریس دور بیستم — Paste Menu & Keyboard Polish

| ID | نیاز | منبع | v1.20 |
|----|------|------|------|
| R20-01 | Multiline paste first line | NerdCalci #193 | ✅ |
| R20-02 | Paste works with history full | GrapheneOS #5358 | ✅ |
| R20-03 | Display context menu copy/paste | Multi-Calc #14 | ✅ |
| R20-04 | Shift+Insert paste | Windows standard | ✅ |
| R20-05 | nothingInMemory Ctrl+R/L | honest UX | ✅ |
| R20-06 | noEqualsPending Enter hint | honest UX | ✅ |
| R20-07 | memoryAdded/Subtracted SR | MS #2315 | ✅ |
| R20-08 | copyAction/pasteAction FA/EN | mobile menu | ✅ |
| R20-09 | Display copy/paste menu (long-press) | GrapheneOS fix | ✅ |
| R20-10 | 254 honest tests | user request | ✅ |

---

### v1.19 — دور نوزدهم (memory SR + undo hints + settings fix)
| فایل | تغییر |
|------|-------|
| `lib/ui/calculator_page.dart` | memory SR · nothingToUndo/Redo · _showBriefHint |
| `lib/ui/widgets/calc_settings_sheet.dart` | restoreSessionHint · keyboardHint in settings |
| `lib/ui/widgets/calc_history_panel.dart` | clear history SR |
| `lib/l10n/app_*.arb` | memory* · nothingToUndo/Redo · restoreSessionHint |
| `test/round19_qa_test.dart` | 6 tests memory/undo/settings/persist |

**تست‌ها:** 247 PASS · smoke 21/21 · `flutter analyze` clean

---

## ۲۸. ماتریس دور نوزدهم — Memory SR & Settings Polish

| ID | نیاز | منبع | v1.19 |
|----|------|------|------|
| R19-01 | Memory store/recall/clear SR | MS #2315 | ✅ |
| R19-02 | nothingToUndo Ctrl+Z feedback | honest UX | ✅ |
| R19-03 | nothingToRedo Ctrl+Y feedback | honest UX | ✅ |
| R19-04 | restoreSession correct subtitle | settings bug | ✅ |
| R19-05 | keyboardHint in settings sheet | MS #1975 | ✅ |
| R19-06 | Clear history button SR | WCAG | ✅ |
| R19-07 | Persian thousands paste ۱٬۲۳۴ | بازار UX | ✅ |
| R19-08 | History persist default #2392 | MS GitHub | ✅ |
| R19-09 | MR/MC guarded when empty | honest memory | ✅ |
| R19-10 | 247 honest tests | user request | ✅ |

---

### v1.18 — دور هجدهم (paste trim + clipboard empty + app bar a11y)
| فایل | تغییر |
|------|-------|
| `lib/utils/paste_parser.dart` | evaluateDetailed · trim 16 digits (MS #162) |
| `lib/calculator.dart` | lastPasteTrimmed flag |
| `lib/ui/calculator_page.dart` | empty/invalid paste feedback · app bar SR · settings refocus |
| `lib/ui/widgets/calc_history_panel.dart` | export button SR |
| `lib/l10n/app_*.arb` | clipboardEmpty · pasteTrimmed |
| `test/round18_qa_test.dart` | 8 tests paste + clipboard + a11y |

**تست‌ها:** 241 PASS · smoke 21/21 · `flutter analyze` clean

---

## ۲۷. ماتریس دور هجدهم — Paste & Clipboard Polish

| ID | نیاز | منبع | v1.18 |
|----|------|------|------|
| R18-01 | Trim pasted numbers >16 digits | MS #162 | ✅ |
| R18-02 | pasteTrimmed user feedback | MS #162 UX | ✅ |
| R18-03 | Empty clipboard Ctrl+V hint | UX SE | ✅ |
| R18-04 | Invalid paste SR announce | WCAG 4.1.3 | ✅ |
| R18-05 | Spaced paste `2 + 3` | MS #2114 | ✅ |
| R18-06 | App bar history/settings SR | TalkBack icons | ✅ |
| R18-07 | Export history button SR | a11y | ✅ |
| R18-08 | Settings close refocus keyboard | MS #2448 | ✅ |
| R18-09 | Expressions not trimmed | honest parse | ✅ |
| R18-10 | 241 honest tests | user request | ✅ |

---

### v1.17 — دور هفدهم (memory/history SR + empty expr copy + refocus undo)
| فایل | تغییر |
|------|-------|
| `lib/ui/widgets/calc_memory_bar.dart` | Semantics M+/MR/MC + memory indicator |
| `lib/ui/widgets/calc_history_panel.dart` | SR label per history entry |
| `lib/ui/calculator_page.dart` | empty Ctrl+Shift+C hint · refocus after undo/redo |
| `lib/l10n/app_*.arb` | semanticsMemoryActive · semanticsHistoryEntry · noExpressionToCopy |
| `test/round17_qa_test.dart` | 7 tests a11y + paste + keyboard |

**تست‌ها:** 233 PASS · smoke 21/21 · `flutter analyze` clean

---

## ۲۶. ماتریس دور هفدهم — Memory/History A11y & Copy Polish

| ID | نیاز | منبع | v1.17 |
|----|------|------|------|
| R17-01 | Memory buttons SR labels FA/EN | OpenCalc #405 | ✅ |
| R17-02 | Memory indicator SR announce | WCAG 4.1.2 | ✅ |
| R17-03 | History entry SR label | TalkBack grid | ✅ |
| R17-04 | Empty Ctrl+Shift+C feedback | honest UX | ✅ |
| R17-05 | Refocus keyboard after undo/redo | MS #2447 | ✅ |
| R17-06 | Persian paste expression ۲×۳ | MS #2114 + FA | ✅ |
| R17-07 | Persian paste colon divide ۱۰:۲ | MS #2114 | ✅ |
| R17-08 | Keyboard works after undo chain | regression | ✅ |
| R17-09 | History tile on wide layout | tablet UX | ✅ |
| R17-10 | 233 honest tests | user request | ✅ |

---

### v1.16 — دور شانزدهم (FA semantics + Shift+− + numpad digits)
| فایل | تغییر |
|------|-------|
| `lib/ui/widgets/keypad_semantics.dart` | KeypadSemantics bundle |
| `lib/ui/widgets/calc_keypad.dart` | localized SR labels FA/EN |
| `lib/ui/widgets/calc_display_panel.dart` | localized display/backspace SR |
| `lib/ui/calculator_page.dart` | Shift+− sign · numpad0–9 · empty export hint |
| `lib/l10n/app_*.arb` | semantics* keys · keyboardHint |
| `test/round16_qa_test.dart` | 6 tests a11y + keyboard |

**تست‌ها:** 226 PASS · smoke 21/21 · `flutter analyze` clean

---

## ۲۵. ماتریس دور شانزدهم — Accessibility & Keyboard Polish

| ID | نیاز | منبع | v1.16 |
|----|------|------|------|
| R16-01 | FA TalkBack «تقسیم» not «÷» | OpenCalc #405 | ✅ |
| R16-02 | All keypad SR labels localized | WCAG 4.1.2 | ✅ |
| R16-03 | Display SR labels localized | WCAG 4.1.2 | ✅ |
| R16-04 | Backspace SR/tooltip localized | FA a11y | ✅ |
| R16-05 | Shift+− toggle sign | MS #1975 | ✅ |
| R16-06 | Numpad 0–9 digits | Windows ManualTests | ✅ |
| R16-07 | Empty history export feedback | honest UX | ✅ |
| R16-08 | keyboardHint Shift+− FA/EN | desktop | ✅ |
| R16-09 | Plain minus still subtract | no regression | ✅ |
| R16-10 | 226 honest tests | user request | ✅ |

---

## ۲۴. ماتریس دور پانزدهم — Memory Persist & History Polish

| ID | نیاز | منبع | v1.15 |
|----|------|------|------|
| R15-01 | Memory restore when session off | MS #2315 | ✅ |
| R15-02 | loadResult Persian digits | بازار / FA UX | ✅ |
| R15-03 | parseNumericText utility | locale parse | ✅ |
| R15-04 | exportHistoryText ASCII | clipboard interop | ✅ |
| R15-05 | Ctrl+Shift+D clear history | Windows docs | ✅ |
| R15-06 | SR announce history cleared | WCAG 4.1.3 | ✅ |
| R15-07 | SR announce item deleted | MS #2474 a11y | ✅ |
| R15-08 | History cap 100 verified | tape limit | ✅ |
| R15-09 | keyboardHint Ctrl+Shift+D FA/EN | desktop | ✅ |
| R15-10 | 219 honest tests | user request | ✅ |

---

## ۲۳. ماتریس دور چهاردهم — Locale Copy & Focus Polish

| ID | نیاز | منبع | v1.14 |
|----|------|------|------|
| R14-01 | Clipboard ASCII (Persian → 0-9) | interoperability | ✅ |
| R14-02 | ٫ decimal key label in FA mode | ubports / بازار | ✅ |
| R14-03 | Comma/٫/، keyboard decimal | GNOME #423 / Wox #4325 | ✅ |
| R14-04 | Refocus after history delete | MS #2474 a11y | ✅ |
| R14-05 | Refocus after history reuse/clear | MS #2474 | ✅ |
| R14-06 | Arrow focus skips disabled keys | jrpool WCAG 2.4.7 | ✅ |
| R14-07 | End key → add when = disabled | Pearson grid | ✅ |
| R14-08 | canInputDecimal guard on comma | honest input | ✅ |
| R14-09 | toClipboardAscii utility | copy pipeline | ✅ |
| R14-10 | 212 honest tests | user request | ✅ |

---

## ۲۲. ماتریس دور سیزدهم — Plain Copy & Disabled Buttons

| ID | نیاز | منبع | v1.13 |
|----|------|------|------|
| R13-01 | copyPlainText never sci (accounting) | Apple #255975372 iOS 18 | ✅ |
| R13-02 | Disabled equals when no op | jrpool / WCAG 3.2 | ✅ |
| R13-03 | Disabled ± on zero | jrpool | ✅ |
| R13-04 | Disabled decimal when dot exists | jrpool | ✅ |
| R13-05 | Disabled digits at max length | jrpool | ✅ |
| R13-06 | Disabled backspace on fresh entry | UX parity | ✅ |
| R13-07 | MR/MC dimmed without memory | Windows Standard | ✅ |
| R13-08 | Running total SR label FA/EN | WCAG 4.1.3 | ✅ |
| R13-09 | Persian decimal mark ٫ in display | بازار UX | ✅ |
| R13-10 | 205 honest tests | user request | ✅ |
| R13-11 | Paste preserves chain operand | GrapheneOS / desktop UX | ✅ |

---

## ۲۱. ماتریس دور دوازدهم — Windows % Chain & Undo

| ID | نیاز | منبع | v1.12 |
|----|------|------|------|
| R12-01 | Windows % in chain `50+10%=55` | MS Standard / #2139 context | ✅ |
| R12-02 | % subtract chain `200-10%=180` | Windows Standard | ✅ |
| R12-03 | Standalone % still ÷100 | mobile/desktop | ✅ |
| R12-04 | % after AC not broken (#2139) | MS #2139 | ✅ |
| R12-05 | Undo stack (32 deep) | Kalkyl / a11y calc | ✅ |
| R12-06 | Redo after undo | desktop UX | ✅ |
| R12-07 | Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z | Windows shortcuts | ✅ |
| R12-08 | History long-press safe copy | MS #2036 parity | ✅ |
| R12-09 | keyboardHint undo l10n FA/EN | desktop | ✅ |
| R12-10 | 190 honest tests | user request | ✅ |

---

## ۲۰. ماتریس دور یازدهم — Paste & Export Polish

| ID | نیاز | منبع | v1.11 |
|----|------|------|------|
| R11-01 | Paste alias x • : for ×÷ | MS #2114 | ✅ |
| R11-02 | Paste LTR expression eval | desktop UX | ✅ |
| R11-03 | Unicode minus − paste | locale paste | ✅ |
| R11-04 | Safe clipboard copy (no crash) | MS #2036/#1971 | ✅ |
| R11-05 | copyFailed snackbar | honest error UX | ✅ |
| R11-06 | Export history text | tape export | ✅ |
| R11-07 | Ctrl+Shift+H export | desktop shortcut | ✅ |
| R11-08 | Export button in history panel | wide + sheet | ✅ |
| R11-09 | 0÷80 edge (Google calc) | myket reviews | ✅ |
| R11-10 | 178 honest tests | user request | ✅ |

---

## ۱۹. ماتریس دور دهم — Running Total & A11y Polish

| ID | نیاز | منبع | v1.10 |
|----|------|------|------|
| R10-01 | Running total live preview | Apple #255778056 iOS 18 | ✅ |
| R10-02 | Toggle running total in settings | user prefs | ✅ |
| R10-03 | High contrast keypad borders | Windows #2182 / WCAG | ✅ |
| R10-04 | Keypad padding 4dp (multiples of 4) | MS layout rule #2182 | ✅ |
| R10-05 | Ctrl+Shift+C copy expression | desktop power users | ✅ |
| R10-06 | Millions plain not sci (6-digit iOS) | Apple #255778836 | ✅ |
| R10-07 | Chained add preview 10+5+3 | shopping subtotal UX | ✅ |
| R10-08 | showRunningTotal persist prefs | honest settings | ✅ |
| R10-09 | FA/EN running total l10n | بازار | ✅ |
| R10-10 | 162 honest tests | user request | ✅ |

---

## ۱۸. ماتریس دور نهم — Float Precision & UX Polish

| ID | نیاز | منبع | v1.9 |
|----|------|------|------|
| R9-01 | 0.1+0.2 → 0.3 (IEEE snap) | HN / Asterisk / StackOverflow | ✅ |
| R9-02 | 1÷3×3 → 1 (internal numericValue) | Windows calc behavior | ✅ |
| R9-03 | DisplayFormat.snap utility | honest floatExp | ✅ |
| R9-04 | history dedupe consecutive dupes | noise reduction UX | ✅ |
| R9-05 | double-tap display copy | iOS/Android calc UX | ✅ |
| R9-06 | tapToCopyDisplay l10n FA/EN | بازار accessibility | ✅ |
| R9-07 | light theme smoke test | theme regression | ✅ |
| R9-08 | memory+display pause lifecycle | #2118 minimize | ✅ |
| R9-09 | numericValue session persist | precision restore | ✅ |
| R9-10 | 154 honest tests | user request | ✅ |

---

## ۱۷. ماتریس دور هشتم — Windows Shortcuts & Lifecycle

| ID | نیاز | منبع | v1.8 |
|----|------|------|------|
| R8-01 | Ctrl+M memory store | Windows calc | ✅ |
| R8-02 | Ctrl+P/Q/R/L memory ops | brownmath / MS docs | ✅ |
| R8-03 | Ctrl+H history sheet | MS shortcut | ✅ |
| R8-04 | Delete = CE | Windows Standard | ✅ |
| R8-05 | F9 toggle sign | Windows Standard | ✅ |
| R8-06 | % keyboard key | desktop | ✅ |
| R8-07 | resume → refocus | #2118 minimize | ✅ |
| R8-08 | exportSession valid | #2458 | ✅ |
| R8-09 | memoryStore unit | backend | ✅ |
| R8-10 | 143 honest tests | user request | ✅ |

---

## ۱۶. ماتریس دور هفتم — A11y & Touch Lock

| ID | نیاز | منبع | v1.7 |
|----|------|------|------|
| R7-01 | Arrow keys در keypad | Pearson grid | ✅ |
| R7-02 | Space فعال‌سازی دکمه | Pearson | ✅ |
| R7-03 | Home→7 / End→= | Pearson | ✅ |
| R7-04 | Focus ring واضح | WCAG 2.4.7 | ✅ |
| R7-05 | Enter بعد history ≠ باز کردن history | MS #1810 | ✅ |
| R7-06 | announce خطای div/0 | WCAG 4.1.3 | ✅ |
| R7-07 | Touch lock (pocket) | بازار reviews | ✅ |
| R7-08 | Keyboard فعال با touch lock | UX | ✅ |
| R7-09 | calc_keypad_grid unit tests | honest QA | ✅ |
| R7-10 | 136 tests | user request | ✅ |

---

## ۱۵. ماتریس دور ششم — UX & Platform Polish

| ID | نیاز | منبع | v1.6 |
|----|------|------|------|
| R6-01 | swipe-left حذف رقم | iOS 18 swipe regression | ✅ |
| R6-02 | numpad ±×÷ desktop | Pearson / Windows | ✅ |
| R6-03 | announce نتیجه پس از = | WCAG 4.1.3 | ✅ |
| R6-04 | snapshot lastOp invariant | MS #2458 | ✅ |
| R6-05 | pendingOp needs accumulator | MS #2458 | ✅ |
| R6-06 | Windows single-instance | GitHub #2386 | ✅ |
| R6-07 | Windows min size 320×480 | #2269 resize | ✅ |
| R6-08 | repeat = regression guard | iOS 18.3 | ✅ |
| R6-09 | FA swipe hint | بازار backspace شکایت | ✅ |
| R6-10 | 125 honest tests | user request | ✅ |

---

## ۱۴. ماتریس دور پنجم — Focus & Lifecycle QA

| ID | نیاز | منبع | v1.5 |
|----|------|------|------|
| R5-01 | کیبورد بعد از بستن history sheet | Flutter #1947 / #2448 | ✅ |
| R5-02 | کیبورد بعد از بستن settings | modal focus trap | ✅ |
| R5-03 | Escape clear + digit بعدی | Windows calc UX | ✅ |
| R5-04 | session restore relaunch واقعی | SharedPreferences mock | ✅ |
| R5-05 | restoreSession off → display 0 | iOS 18 stale | ✅ |
| R5-06 | clear → persist → relaunch 0 | #2392 Windows | ✅ |
| R5-07 | side history reuse wide layout | desktop dual pane | ✅ |
| R5-08 | pending op highlight | operator UX | ✅ |
| R5-09 | landscape phone layout | Material mobile | ✅ |
| R5-10 | backend edge-case matrix | honest unit QA | ✅ |
| R5-11 | 118 tests no mock cheating | user request | ✅ |

---

## ۱۳. ماتریس دور چهارم — Responsive & QA

| ID | نیاز | منبع | v1.4 |
|----|------|------|------|
| R4-01 | compact 320px بدون overflow | Calclet mobile-first | ✅ |
| R4-02 | phone portrait/landscape | Material | ✅ |
| R4-03 | tablet 768–1024 | side history ≥900 | ✅ |
| R4-04 | desktop 1280+ dual pane | Windows calc | ✅ |
| R4-05 | touch ≥48dp | WCAG 2.5.5 | ✅ |
| R4-06 | 8dp grid padding | MS #2182 lesson | ✅ |
| R4-07 | error → persist clear | iOS stale fix | ✅ |
| R4-08 | 101 honest tests | user request | ✅ |
| R4-09 | smoke CI toolchain | project | ✅ |
| R4-10 | golden DPI tests | MS #2182 | P2 |

---

## ۱۲. ماتریس دور سوم — یافته‌های جدید

### Windows (#2182, #2275, #2386, #2458)
| ID | مشکل گزارش‌شده | اقدام اپ |
|----|----------------|----------|
| W3-01 | misalign دکمه‌ها 125%/150% scale | layout ثابت Expanded — تست golden P2 |
| W3-02 | پنجره duplicate + frozen | single-instance P2 |
| W3-03 | crash snapshot malformed URI | ✅ validation session |
| W3-04 | comma locale نادیده (#SuperUser) | ✅ `,` و `٫` در keyboard/paste |

### iOS 18 (Apple Community, TechIssuesToday)
| ID | مشکل | اقدام اپ |
|----|------|----------|
| I3-01 | repeat `=` حذف شد | ✅ v1.1 |
| I3-02 | AC clear ولی reopen stale | ✅ persist on clear + restoreSession toggle |
| I3-03 | sci notation زود (6 رقم) | ✅ threshold 1e10 |
| I3-04 | C button → backspace adaptive | ✅ C + long-press CE |
| I3-05 | expression scroll افقی | ✅ v1.3 |

### Android / Google Calculator
| ID | مشکل | اقدام اپ |
|----|------|----------|
| A3-01 | history swipe-down hidden | ✅ v1.3 + دکمه history |
| A3-02 | tap history insert | ✅ v1.2 |
| A3-03 | history sync cloud | privacy: local-only ✅ |

### فارسی (بازار، مایکت، Samsung FA)
| ID | مشکل | اقدام اپ |
|----|------|----------|
| F3-01 | تبلیغات زیاد | ✅ ad-free + privacy note |
| F3-02 | ممیز/ارقام فارسی | ✅ v1.3 |
| F3-03 | حذف رقم بدون clear کل | ✅ backspace |
| F3-04 | PEMDAS اشتباه | ✅ LTR + about |
| F3-05 | قفل لمس | P2 |
