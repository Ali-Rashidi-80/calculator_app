import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/ui/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 16 — localized TalkBack labels, Shift+− sign, numpad digits, empty export.
void main() {
  group('Persian semantics labels (OpenCalc #405 / WCAG 4.1.2)', () {
    testWidgets('divide button announces تقسیم in FA locale', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      final btn = tester.widget<CalcButton>(find.byKey(const Key('btn_div')));
      expect(btn.semanticsLabel, 'تقسیم');
    });

    testWidgets('divide button announces Divide in EN locale', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      final btn = tester.widget<CalcButton>(find.byKey(const Key('btn_div')));
      expect(btn.semanticsLabel, 'Divide');
    });

    testWidgets('display announces نتیجه in FA locale', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      await tapCalc(tester, '7');

      final semantics = tester.getSemantics(
        find.byKey(const Key('display_gesture')),
      );
      expect(semantics.label, contains('نتیجه:'));
      expect(semantics.label, contains('۷'));
    });
  });

  group('Shift+Minus toggle sign (MS #1975)', () {
    testWidgets('Shift+minus negates display', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '5');
      expect(displayText(tester), '5');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(displayText(tester), '-5');
    });

    test('plain minus key still sets subtract operation', () {
      final c = Calculator();
      c.inputDigit('5');
      c.setOperation('-');
      expect(c.pendingOp, '-');
    });
  });

  group('Numpad digit keys (Windows ManualTests)', () {
    testWidgets('numpad digits enter numbers', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad3);
      await tester.pump();

      expect(displayText(tester), '123');
    });
  });

  group('Empty history export feedback', () {
    testWidgets('Ctrl+Shift+H with no history shows empty message', (
      tester,
    ) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('No calculations yet'), findsOneWidget);
      expect(find.text('Copied'), findsNothing);
    });
  });
}
