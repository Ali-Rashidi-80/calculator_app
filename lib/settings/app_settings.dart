import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';



/// Persisted theme + locale preferences.

class AppSettings extends ChangeNotifier {

  AppSettings._(this._prefs);



  static const _keyTheme = 'theme_mode';

  static const _keyLocale = 'locale_code';

  static const _keyHaptics = 'haptics_enabled';

  static const _keyPersistHistory = 'persist_history';

  static const _keyRestoreSession = 'restore_session';

  static const _keyPersianDigits = 'persian_digits';

  static const _keyTouchLock = 'touch_lock';
  static const _keyRunningTotal = 'show_running_total';



  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;

  Locale? _locale;

  bool _hapticsEnabled = true;

  bool _persistHistory = true;

  bool _restoreSession = true;

  bool _persianDigits = false;

  bool _touchLock = false;
  bool _showRunningTotal = true;



  ThemeMode get themeMode => _themeMode;

  Locale? get locale => _locale;

  bool get hapticsEnabled => _hapticsEnabled;

  bool get persistHistory => _persistHistory;

  bool get restoreSession => _restoreSession;

  bool get persianDigits => _persianDigits;

  bool get touchLock => _touchLock;
  bool get showRunningTotal => _showRunningTotal;

  bool get touchInputEnabled => !_touchLock;



  /// Whether UI should show Eastern Arabic digits.

  bool get usePersianDigits =>

      _persianDigits || _locale?.languageCode == 'fa';



  static Future<AppSettings> load() async {

    final prefs = await SharedPreferences.getInstance();

    final settings = AppSettings._(prefs);

    final themeIndex = prefs.getInt(_keyTheme);

    if (themeIndex != null && themeIndex >= 0 && themeIndex <= 2) {

      settings._themeMode = ThemeMode.values[themeIndex];

    }

    final code = prefs.getString(_keyLocale);

    if (code == 'en' || code == 'fa') {

      settings._locale = Locale(code!);

    }

    settings._hapticsEnabled = prefs.getBool(_keyHaptics) ?? true;

    settings._persistHistory = prefs.getBool(_keyPersistHistory) ?? true;

    settings._restoreSession = prefs.getBool(_keyRestoreSession) ?? true;

    settings._persianDigits = prefs.getBool(_keyPersianDigits) ?? (code == 'fa');

    settings._touchLock = prefs.getBool(_keyTouchLock) ?? false;
    settings._showRunningTotal = prefs.getBool(_keyRunningTotal) ?? true;

    return settings;

  }



  Future<void> setThemeMode(ThemeMode mode) async {

    if (_themeMode == mode) return;

    _themeMode = mode;

    await _prefs.setInt(_keyTheme, mode.index);

    notifyListeners();

  }



  Future<void> setLocale(Locale? locale) async {

    if (_locale == locale) return;

    _locale = locale;

    if (locale == null) {

      await _prefs.remove(_keyLocale);

    } else {

      await _prefs.setString(_keyLocale, locale.languageCode);

    }

    notifyListeners();

  }



  Future<void> setHapticsEnabled(bool enabled) async {

    if (_hapticsEnabled == enabled) return;

    _hapticsEnabled = enabled;

    await _prefs.setBool(_keyHaptics, enabled);

    notifyListeners();

  }



  Future<void> setPersistHistory(bool enabled) async {

    if (_persistHistory == enabled) return;

    _persistHistory = enabled;

    await _prefs.setBool(_keyPersistHistory, enabled);

    notifyListeners();

  }



  Future<void> setRestoreSession(bool enabled) async {

    if (_restoreSession == enabled) return;

    _restoreSession = enabled;

    await _prefs.setBool(_keyRestoreSession, enabled);

    notifyListeners();

  }



  Future<void> setPersianDigits(bool enabled) async {

    if (_persianDigits == enabled) return;

    _persianDigits = enabled;

    await _prefs.setBool(_keyPersianDigits, enabled);

    notifyListeners();

  }



  Future<void> setTouchLock(bool enabled) async {
    if (_touchLock == enabled) return;
    _touchLock = enabled;
    await _prefs.setBool(_keyTouchLock, enabled);
    notifyListeners();
  }

  Future<void> setShowRunningTotal(bool enabled) async {
    if (_showRunningTotal == enabled) return;
    _showRunningTotal = enabled;
    await _prefs.setBool(_keyRunningTotal, enabled);
    notifyListeners();
  }
}
