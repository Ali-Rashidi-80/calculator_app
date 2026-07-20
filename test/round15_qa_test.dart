import 'package:calculator_app/calc_history.dart';
import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Round 15 — memory persist #2315, Persian loadResult, Ctrl+Shift+D, export ASCII.
void main() {
  group('parseNumericText / loadResult (Persian & locale)', () {
    test('parseNumericText accepts Persian digits', () {
      expect(Calculator.parseNumericText('۴۲'), 42);
      expect(Calculator.parseNumericText('۳٫۱۴'), closeTo(3.14, 1e-9));
    });

    test('loadResult loads Persian result text', () {
      final c = Calculator();
      c.loadResult('۹۹');
      expect(c.display, '99');
    });

    test('loadResult rejects invalid text', () {
      final c = Calculator();
      c.loadResult('not-a-number');
      expect(c.display, '0');
    });
  });

  group('History export ASCII', () {
    test('exportHistoryText is plain ASCII', () {
      final c = Calculator();
      c.inputDigit('1');
      c.setOperation('+');
      c.inputDigit('1');
      c.equals();
      expect(c.exportHistoryText(), '1 + 1 = 2');
      expect(c.exportHistoryText().contains('۱'), isFalse);
    });
  });

  group('Memory persist when session restore off (#2315)', () {
    testWidgets('memory restored after relaunch with restoreSession off', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'restore_session': false,
        'calc_memory_v1': 42.0,
      });
      setTestViewport(tester, const Size(390, 844));
      final settings = await AppSettings.load();
      await tester.pumpWidget(CalculatorApp(settings: settings));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('memory_indicator')), findsOneWidget);
    });
  });

  group('Ctrl+Shift+D clear history', () {
    testWidgets('clears history tape', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '3');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '3');
      await tapCalc(tester, 'eq');
      expect(find.byKey(const Key('history_list')), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(find.byKey(const Key('history_list')), findsNothing);
    });
  });

  group('History max entries', () {
    test('caps at 100 entries', () {
      final c = Calculator();
      for (var i = 0; i < 105; i++) {
        c.inputDigit('1');
        c.setOperation('+');
        for (final ch in '${i + 1}'.split('')) {
          c.inputDigit(ch);
        }
        c.equals();
        c.clear();
      }
      expect(c.history.entries.length, CalcHistory.maxEntries);
    });
  });
}
