import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/utils/paste_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 11 — paste aliases, safe copy, history export, edge division.
void main() {
  group('Paste expression (MS #2114)', () {
    test('paste 2 x 3 evaluates to 6', () {
      final c = Calculator();
      expect(c.pasteFromText('2 x 3'), isTrue);
      expect(c.display, '6');
    });

    test('paste 2+3*4 LTR equals 20', () {
      final c = Calculator();
      expect(c.pasteFromText('2+3*4'), isTrue);
      expect(c.display, '20');
    });

    test('division by zero yields infinity for calculator guard', () {
      expect(PasteParser.evaluate('1/0'), double.infinity);
    });

    test('calculator paste 1/0 throws division error', () {
      final c = Calculator();
      expect(() => c.pasteFromText('1/0'), throwsA(isA<CalculatorError>()));
    });
  });

  group('History export', () {
    test('exportHistoryText newest first', () {
      final c = Calculator();
      c.inputDigit('1');
      c.setOperation('+');
      c.inputDigit('1');
      c.equals();
      c.inputDigit('2');
      c.setOperation('+');
      c.inputDigit('2');
      c.equals();
      final text = c.exportHistoryText();
      expect(text, contains('1 + 1 = 2'));
      expect(text, contains('2 + 2 = 4'));
      expect(text.indexOf('2 + 2'), lessThan(text.indexOf('1 + 1')));
    });
  });

  group('Google calc 0 divide edge', () {
    test('0 divided by 80 equals 0', () {
      final c = Calculator();
      c.inputDigit('0');
      c.setOperation('÷');
      c.inputDigit('8');
      c.inputDigit('0');
      c.equals();
      expect(c.display, '0');
    });
  });

  group('History export UI', () {
    testWidgets('export button visible when history has entries', (
      tester,
    ) async {
      setTestViewport(tester, const Size(1280, 900));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '3');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '3');
      await tapCalc(tester, 'eq');

      expect(find.byKey(const Key('btn_export_history')), findsOneWidget);
    });

    testWidgets('Ctrl+Shift+H shows copied snackbar', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '5');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '5');
      await tapCalc(tester, 'eq');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Copied'), findsOneWidget);
    });
  });
}
