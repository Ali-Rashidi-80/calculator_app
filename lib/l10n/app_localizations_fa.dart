// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'ماشین‌حساب';

  @override
  String get errorDivisionByZero => 'تقسیم بر صفر ممکن نیست';

  @override
  String get errorOverflow => 'عدد بیش از حد بزرگ است';

  @override
  String get errorInvalidPaste => 'عدد نامعتبر برای چسباندن';

  @override
  String get copied => 'کپی شد';

  @override
  String get copyFailed => 'کپی ناموفق — دسترسی کلیپ‌بورد را بررسی کنید';

  @override
  String get cleared => 'پاک شد';

  @override
  String get history => 'تاریخچه';

  @override
  String get historyEmpty => 'هنوز محاسبه‌ای انجام نشده';

  @override
  String get clearHistory => 'پاک کردن تاریخچه';

  @override
  String get deleteHistoryItem => 'حذف';

  @override
  String get settings => 'تنظیمات';

  @override
  String get theme => 'تم';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get language => 'زبان';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get haptics => 'لرزش دکمه‌ها';

  @override
  String get persistHistory => 'نگه‌داشتن تاریخچه بعد از بستن';

  @override
  String get restoreSession => 'بازیابی آخرین جلسه هنگام باز کردن';

  @override
  String get persianDigits => 'نمایش اعداد فارسی (۰–۹)';

  @override
  String get privacyNote =>
      'همه داده‌ها روی دستگاه شما می‌ماند. بدون تبلیغ. بدون ابر.';

  @override
  String get swipeHistoryHint =>
      'برای تاریخچه به پایین بکشید · برای حذف رقم به چپ بکشید';

  @override
  String get aboutCalc => 'درباره';

  @override
  String get aboutChainedCalc =>
      'عملیات از چپ به راست انجام می‌شود (نه PEMDAS). مثال: ۲ + ۳ × ۴ = ۲۰. برای تکرار آخرین عمل، دوباره = بزنید.';

  @override
  String get keyboardHint => 'لیست کامل در تنظیمات → میانبرهای کیبورد';

  @override
  String get keyboardShortcutsTitle => 'میانبرهای کیبورد';

  @override
  String get keyboardShortcutsTooltip => 'میانبرهای کیبورد';

  @override
  String get keyboardShortcutNav => 'پیمایش';

  @override
  String get keyboardShortcutNavKeys =>
      'فلش‌ها = جابجایی فوکوس · Home / End · Space = فعال‌سازی کلید فوکوس‌شده · Enter = مساوی · Esc = پاک همه';

  @override
  String get keyboardShortcutEdit => 'ویرایش';

  @override
  String get keyboardShortcutEditKeys =>
      'Ctrl+Z بازگشت · Ctrl+Y بازانجام · Ctrl+V چسباندن · Shift+Insert چسباندن · Backspace · Delete = پاک ورودی';

  @override
  String get keyboardShortcutMemory => 'حافظه';

  @override
  String get keyboardShortcutMemoryKeys =>
      'Ctrl+M ذخیره · Ctrl+P جمع · Ctrl+Q کسر · Ctrl+R بازیابی · Ctrl+L پاک';

  @override
  String get keyboardShortcutHistory => 'تاریخچه';

  @override
  String get keyboardShortcutHistoryKeys =>
      'Ctrl+H باز کردن · Ctrl+Shift+H خروجی · Ctrl+Shift+D پاک همه';

  @override
  String get keyboardShortcutCopy => 'کپی و چسباندن';

  @override
  String get keyboardShortcutCopyKeys =>
      'Ctrl+Shift+C کپی عبارت · لمس طولانی نمایشگر = منوی کپی/چسباندن';

  @override
  String get keyboardShortcutSign => 'علامت';

  @override
  String get keyboardShortcutSignKeys => 'F9 یا Shift+− تغییر علامت';

  @override
  String get semanticsClear => 'پاک کردن همه';

  @override
  String get semanticsToggleSign => 'تغییر علامت';

  @override
  String get semanticsPercent => 'درصد';

  @override
  String get semanticsDivide => 'تقسیم';

  @override
  String get semanticsMultiply => 'ضرب';

  @override
  String get semanticsSubtract => 'تفریق';

  @override
  String get semanticsAdd => 'جمع';

  @override
  String get semanticsDecimal => 'ممیز اعشار';

  @override
  String get semanticsEquals => 'مساوی';

  @override
  String get semanticsBackspace => 'حذف رقم';

  @override
  String semanticsDisplayResult(String value) {
    return 'نتیجه: $value';
  }

  @override
  String semanticsDisplayError(String message) {
    return 'خطا: $message';
  }

  @override
  String get semanticsMemoryActive => 'حافظه مقدار ذخیره‌شده دارد';

  @override
  String semanticsHistoryEntry(String expression, String result) {
    return '$expression، مساوی $result';
  }

  @override
  String get noExpressionToCopy => 'عبارتی برای کپی وجود ندارد';

  @override
  String get clipboardEmpty => 'کلیپ‌بورد خالی است';

  @override
  String get pasteTrimmed => 'عدد چسبانده‌شده برای نمایش کوتاه شد';

  @override
  String get nothingToUndo => 'چیزی برای بازگشت نیست';

  @override
  String get nothingToRedo => 'چیزی برای بازانجام نیست';

  @override
  String get memoryStored => 'مقدار در حافظه ذخیره شد';

  @override
  String get memoryRecalled => 'مقدار از حافظه بازیابی شد';

  @override
  String get memoryClearedAnnounce => 'حافظه پاک شد';

  @override
  String get restoreSessionHint =>
      'بازیابی نمایشگر و عملیات معلق هنگام باز کردن مجدد';

  @override
  String get nothingInMemory => 'حافظه خالی است';

  @override
  String get noEqualsPending => 'محاسبه‌ای برای تکمیل نیست';

  @override
  String get copyAction => 'کپی';

  @override
  String get pasteAction => 'چسباندن';

  @override
  String get memoryAdded => 'به حافظه اضافه شد';

  @override
  String get memorySubtracted => 'از حافظه کسر شد';

  @override
  String get touchLock => 'قفل لمس (کیبورد فعال می‌ماند)';

  @override
  String get touchLockedHint =>
      'لمس قفل است — از کیبورد استفاده کنید یا در تنظیمات باز کنید';

  @override
  String get tapToCopyHistory => 'لمس = استفاده مجدد · دوبار-لمس نمایشگر = کپی';

  @override
  String get tapToCopyDisplay =>
      'لمس طولانی نمایشگر برای کپی/چسباندن · دوبار-لمس برای کپی';

  @override
  String get memoryAdd => 'جمع در حافظه (M+)';

  @override
  String get memorySubtract => 'کسر از حافظه (M−)';

  @override
  String get memoryRecall => 'بازیابی حافظه (MR)';

  @override
  String get memoryClear => 'پاک حافظه (MC)';

  @override
  String get memoryIndicator => 'M';

  @override
  String get clearEntryHint =>
      'نگه‌داشتن C یا Delete فقط ورودی را پاک می‌کند (CE)';

  @override
  String get showRunningTotal => 'پیش‌نمایش جمع تجمعی';

  @override
  String get showRunningTotalHint =>
      'جمع لحظه‌ای هنگام تایپ (مثل iOS 17 — مناسب جمع خرید)';

  @override
  String get exportHistory => 'خروجی تاریخچه به کلیپ‌بورد';

  @override
  String get historyCleared => 'تاریخچه پاک شد';

  @override
  String get historyItemDeleted => 'مورد تاریخچه حذف شد';

  @override
  String runningTotalPreview(String total) {
    return 'جمع میانی: $total';
  }
}
