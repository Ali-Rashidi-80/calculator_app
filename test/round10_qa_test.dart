import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/settings/app_settings.dart';
import 'package:calculator_app/theme/app_theme.dart';
import 'package:calculator_app/ui/calc_layout.dart';
import 'package:calculator_app/ui/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Round 10 — running total (iOS 17), high contrast, grid alignment, copy expr.
void main() {
  group('Running total preview (iOS 17 / Apple #255778056)', () {
    test('shows live subtotal while entering second operand', () {
      final c = Calculator();
      c.inputDigit('1');
      c.inputDigit('0');
      c.setOperation('+');
      c.inputDigit('5');
      expect(c.runningTotal, '15');

      c.setOperation('+');
      c.inputDigit('3');
      expect(c.runningTotal, '18');
    });

    test('null when fresh entry after operator', () {
      final c = Calculator();
      c.inputDigit('2');
      c.setOperation('+');
      expect(c.runningTotal, isNull);
    });
  });

  group('Scientific notation threshold (iOS 18 six-digit complaint)', () {
    test('millions display in plain form not sci notation', () {
      final c = Calculator();
      expect(c.pasteFromText('999999'), isTrue);
      expect(c.display, '999999');
    });
  });

  group('Keypad grid multiples-of-four (#2182 Windows misalign)', () {
    test('button padding is always 4dp', () {
      expect(CalcLayout(const Size(320, 640)).buttonPadding, 4);
      expect(CalcLayout(const Size(1280, 800)).buttonPadding, 4);
    });
  });

  group('Running total UI', () {
    testWidgets('running total visible during chain when enabled', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, '0');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '5');

      expect(find.byKey(const Key('running_total')), findsOneWidget);
      expect(find.text('15'), findsWidgets);
    });

    testWidgets('running total hidden when setting off', (tester) async {
      SharedPreferences.setMockInitialValues({'show_running_total': false});
      setTestViewport(tester, const Size(390, 844));
      final settings = await AppSettings.load();
      await tester.pumpWidget(CalculatorApp(settings: settings));
      await tester.pumpAndSettle();

      await tapCalc(tester, '1');
      await tapCalc(tester, '0');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '5');

      expect(find.byKey(const Key('running_total')), findsNothing);
    });
  });

  group('High contrast keypad (#2182 / WCAG)', () {
    testWidgets('buttons show outline border in high contrast mode', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              highContrast: true,
            ),
            child: Scaffold(
              body: Row(
                children: [
                  CalcButton(label: '7', id: '7', onTap: _noop),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CalcButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(container.decoration, isA<BoxDecoration>());
      final deco = container.decoration! as BoxDecoration;
      expect(deco.border, isNotNull);
      expect(deco.border!.top.width, 2);
    });
  });

  group('Ctrl+Shift+C copy expression', () {
    testWidgets('shows copied snackbar for pending expression', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '4');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '2');
      expect(find.textContaining('4 + 2'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Copied'), findsOneWidget);
    });
  });
}

void _noop() {}
