import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/settings/app_settings.dart';
import 'package:calculator_app/utils/digit_locale.dart';
import 'package:calculator_app/utils/paste_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Round 23 — final polish High bugs (paste locale, loadResult, touch lock, %).
void main() {
  group('H1 Paste locale (MS #2396)', () {
    test('EU comma decimal 3,14', () {
      expect(PasteParser.evaluate('3,14'), 3.14);
      expect(DigitLocale.normalizePaste('3,14'), '3.14');
    });

    test('EU thousands + decimal 1.234,56', () {
      expect(DigitLocale.normalizePaste('1.234,56'), '1234.56');
      expect(PasteParser.evaluate('1.234,56'), 1234.56);
    });

    test('US thousands + decimal 1,234.56', () {
      expect(DigitLocale.normalizePaste('1,234.56'), '1234.56');
      expect(PasteParser.evaluate('1,234.56'), 1234.56);
    });

    test('Persian thousands paste', () {
      expect(PasteParser.evaluate('۱٬۲۳۴'), 1234);
    });

    test('expression paste with EU decimals', () {
      expect(PasteParser.evaluate('1,5+2,5'), 4);
    });

    test('0.011 pastes as fraction not 11', () {
      expect(PasteParser.evaluate('0.011'), 0.011);
    });
  });

  group('H2 loadResult clears equals-repeat', () {
    test('reuse history then equals does not reapply last op', () {
      final c = Calculator();
      c.inputDigit('5');
      c.setOperation('+');
      c.inputDigit('3');
      c.equals();
      expect(c.display, '8');
      expect(c.history.entries, isNotEmpty);

      c.loadResult('99');
      expect(c.display, '99');
      c.equals();
      expect(c.display, '99');
    });
  });

  group('H5 Windows percent ×/÷', () {
    test('50×10% shows 0.1 then equals 5', () {
      final c = Calculator();
      c.inputDigit('5');
      c.inputDigit('0');
      c.setOperation('×');
      c.inputDigit('1');
      c.inputDigit('0');
      c.percent();
      expect(c.display, '0.1');
      c.equals();
      expect(c.display, '5');
    });

    test('50+10% still shows 5 then equals 55', () {
      final c = Calculator();
      c.inputDigit('5');
      c.inputDigit('0');
      c.setOperation('+');
      c.inputDigit('1');
      c.inputDigit('0');
      c.percent();
      expect(c.display, '5');
      c.equals();
      expect(c.display, '55');
    });
  });

  group('H6 FA persian digits toggle can turn OFF', () {
    test('usePersianDigits follows stored flag even in fa', () async {
      SharedPreferences.setMockInitialValues({
        'locale_code': 'fa',
        'persian_digits': true,
      });
      final s = await AppSettings.load();
      expect(s.locale?.languageCode, 'fa');
      expect(s.usePersianDigits, isTrue);

      await s.setPersianDigits(false);
      expect(s.usePersianDigits, isFalse);

      final s2 = await AppSettings.load();
      expect(s2.usePersianDigits, isFalse);
    });

    test('FA→EN→FA preserves explicit digits OFF', () async {
      SharedPreferences.setMockInitialValues({
        'locale_code': 'fa',
        'persian_digits': true,
      });
      final s = await AppSettings.load();
      await s.setPersianDigits(false);
      expect(s.usePersianDigits, isFalse);

      await s.setLocale(const Locale('en'));
      expect(s.usePersianDigits, isFalse);

      await s.setLocale(const Locale('fa'));
      expect(s.usePersianDigits, isFalse);
      expect(s.locale?.languageCode, 'fa');
    });

    test('first switch EN→FA defaults digits ON when unset', () async {
      SharedPreferences.setMockInitialValues({'locale_code': 'en'});
      final s = await AppSettings.load();
      expect(s.usePersianDigits, isFalse);

      await s.setLocale(const Locale('fa'));
      expect(s.usePersianDigits, isTrue);
    });
  });

  group('H3 Touch lock covers display and memory', () {
    testWidgets('memory tap while locked shows hint; keyboard still works', (
      tester,
    ) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, prefs: {'touch_lock': true});

      await tester.tap(find.byKey(const Key('btn_m_add')));
      await tester.pump();
      expect(find.textContaining('Touch locked'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
      await tester.pump();
      expect(displayText(tester), '7');
    });

    testWidgets('MR/MC stay disabled when locked with empty memory', (
      tester,
    ) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, prefs: {'touch_lock': true});

      final mr = find.descendant(
        of: find.byKey(const Key('btn_m_recall')),
        matching: find.byType(InkWell),
      );
      final mc = find.descendant(
        of: find.byKey(const Key('btn_m_clear')),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(mr).onTap, isNull);
      expect(tester.widget<InkWell>(mc).onTap, isNull);
    });
  });

  group('H4 Space docs match behavior', () {
    testWidgets('Space activates focused key not equals', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(displayText(tester), '7');
    });
  });
}
