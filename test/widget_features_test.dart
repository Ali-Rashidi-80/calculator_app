import 'package:calculator_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  group('Feature widget tests', () {
    testWidgets('memory M+ shows indicator', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '5');
      await tester.tap(find.byKey(const Key('btn_m_add')));
      await tester.pump();

      expect(find.byKey(const Key('memory_indicator')), findsOneWidget);
    });

    testWidgets('memory M- and MR recall value', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, '0');
      await tester.tap(find.byKey(const Key('btn_m_add')));
      await tester.pump();
      await tapCalc(tester, 'clear');
      await tapCalc(tester, '3');
      await tester.tap(find.byKey(const Key('btn_m_sub')));
      await tester.pump();
      await tapCalc(tester, 'clear');
      await tester.tap(find.byKey(const Key('btn_m_recall')));
      await tester.pump();

      expect(displayText(tester), '7');
    });

    testWidgets('long-press C clears entry only (CE)', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '3');
      await tester.longPress(find.byKey(const Key('btn_clear')));
      await tester.pump();

      expect(displayText(tester), '0');
      expect(
        tester.widget<Text>(find.byKey(const Key('expression'))).data,
        '12 +',
      );
    });

    testWidgets('Persian locale shows Persian digits on display', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      await tapCalc(tester, '5');
      expect(displayText(tester), '۵');
    });

    testWidgets('history records after equals on phone', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'eq');

      await tester.tap(find.byKey(const Key('btn_history')));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 + 2'), findsWidgets);
    });

    testWidgets('settings sheet opens', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_settings')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Keep history after close'), findsOneWidget);
    });
  });

  group('AppSettings persistence', () {
    test('settings round-trip via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await AppSettings.load();
      await s.setThemeMode(ThemeMode.dark);
      await s.setLocale(const Locale('fa'));
      await s.setHapticsEnabled(false);
      await s.setPersistHistory(false);
      await s.setRestoreSession(false);
      await s.setPersianDigits(true);

      final s2 = await AppSettings.load();
      expect(s2.themeMode, ThemeMode.dark);
      expect(s2.locale?.languageCode, 'fa');
      expect(s2.hapticsEnabled, isFalse);
      expect(s2.persistHistory, isFalse);
      expect(s2.restoreSession, isFalse);
      expect(s2.persianDigits, isTrue);
    });
  });
}
