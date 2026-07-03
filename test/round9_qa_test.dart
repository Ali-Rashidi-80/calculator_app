import 'package:calculator_app/calc_history.dart';
import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Round 9 — float precision, double-tap copy, light theme, history dedupe, lifecycle.
void main() {
  group('Floating-point precision (HN / Asterisk lesson)', () {
    test('1 divide 3 multiply 3 equals 1 via keypad', () {
      final c = Calculator();
      c.inputDigit('1');
      c.setOperation('÷');
      c.inputDigit('3');
      c.equals();
      c.setOperation('×');
      c.inputDigit('3');
      c.equals();
      expect(c.display, '1');
    });

    test('0.1 plus 0.2 minus 0.3 equals 0', () {
      final c = Calculator();
      c.inputDigit('0');
      c.inputDecimal();
      c.inputDigit('1');
      c.setOperation('+');
      c.inputDigit('0');
      c.inputDecimal();
      c.inputDigit('2');
      c.equals();
      c.setOperation('-');
      c.inputDigit('0');
      c.inputDecimal();
      c.inputDigit('3');
      c.equals();
      expect(c.display, '0');
    });
  });

  group('History dedupe (noise reduction)', () {
    test('identical expression+result not duplicated', () {
      final h = CalcHistory();
      h.add('1 + 1', '2');
      h.add('1 + 1', '2');
      expect(h.entries.length, 1);
    });
  });

  group('Double-tap display copy', () {
    testWidgets('double-tap display shows copied snackbar', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '8');
      await tester.tap(find.byKey(const Key('display_gesture')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('display_gesture')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Copied'), findsOneWidget);
    });
  });

  group('Light theme smoke', () {
    testWidgets('light theme renders and calculates', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      SharedPreferences.setMockInitialValues({'theme_mode': 1});
      final settings = await AppSettings.load();
      await tester.pumpWidget(CalculatorApp(settings: settings));
      await tester.pumpAndSettle();

      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.light);
      expect(tester.takeException(), isNull);

      await tapCalc(tester, '3');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '4');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '7');
    });
  });

  group('Memory survives pause (#2118)', () {
    testWidgets('memory and display persist after pause relaunch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      setTestViewport(tester, const Size(390, 844));

      await pumpCalculatorApp(tester);
      await tapCalc(tester, '6');
      await tester.tap(find.byKey(const Key('btn_m_add')));
      await tester.pump();
      await tapCalc(tester, 'clear');
      await tapCalc(tester, '5');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      await relaunchCalculatorApp(tester);
      expect(displayText(tester), '5');
      expect(find.byKey(const Key('memory_indicator')), findsOneWidget);
    });
  });
}
