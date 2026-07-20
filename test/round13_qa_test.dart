import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/utils/digit_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 13 — plain copy (iOS 18), disabled buttons (jrpool a11y), Persian decimal.
void main() {
  group('Plain clipboard copy (Apple #255975372)', () {
    test('copyPlainText never uses scientific notation', () {
      final c = Calculator();
      expect(c.pasteFromText('10000000000'), isTrue);
      expect(c.display, contains('e'));
      expect(c.copyPlainText, '10000000000');
      expect(c.copyPlainText.contains('e'), isFalse);
    });

    test('copyPlainText for accounting sum', () {
      final c = Calculator();
      c.pasteFromText('1234567.89');
      c.setOperation('+');
      c.pasteFromText('987654.32');
      c.equals();
      expect(c.display, '2222222.21');
      expect(c.copyPlainText, '2222222.21');
    });

    test('copyPlainText returns display when already plain', () {
      final c = Calculator();
      c.inputDigit('4');
      c.inputDigit('2');
      expect(c.copyPlainText, '42');
    });

    test('paste during chain preserves pending operation', () {
      final c = Calculator();
      c.inputDigit('5');
      c.setOperation('+');
      expect(c.pasteFromText('3'), isTrue);
      expect(c.pendingOp, '+');
      c.equals();
      expect(c.display, '8');
    });
  });

  group('Disabled button state getters (jrpool / WCAG 3.2)', () {
    test('canEquals false on fresh calculator', () {
      final c = Calculator();
      expect(c.canEquals, isFalse);
    });

    test('canEquals true with pending operation', () {
      final c = Calculator();
      c.inputDigit('5');
      c.setOperation('+');
      expect(c.canEquals, isTrue);
    });

    test('canEquals true after result for repeat equals', () {
      final c = Calculator();
      c.inputDigit('2');
      c.setOperation('+');
      c.inputDigit('3');
      c.equals();
      expect(c.canEquals, isTrue);
    });

    test('canToggleSign false on zero', () {
      final c = Calculator();
      expect(c.canToggleSign, isFalse);
    });

    test('canInputDecimal false when dot present', () {
      final c = Calculator();
      c.inputDecimal();
      expect(c.canInputDecimal, isFalse);
    });

    test('canBackspace false on fresh entry after op', () {
      final c = Calculator();
      c.inputDigit('9');
      c.setOperation('+');
      expect(c.canBackspace, isFalse);
    });

    test('canMemoryRecall false without memory', () {
      expect(Calculator().canMemoryRecall, isFalse);
    });
  });

  group('Persian decimal separator', () {
    test('formatDisplay uses Arabic decimal mark', () {
      expect(DigitLocale.formatDisplay('3.14', usePersianDigits: true), '۳٫۱۴');
    });
  });

  group('Disabled equals button UI', () {
    testWidgets('tap equals on fresh display does nothing', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, 'eq');
      expect(displayText(tester), '0');
    });

    testWidgets('equals evaluates chain when pending op exists', (
      tester,
    ) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '5');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '3');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '8');
    });

    testWidgets('MR has no onTap without memory', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      final ink = find.descendant(
        of: find.byKey(const Key('btn_m_recall')),
        matching: find.byType(InkWell),
      );
      expect(ink, findsOneWidget);
      expect(tester.widget<InkWell>(ink).onTap, isNull);
    });
  });
}
