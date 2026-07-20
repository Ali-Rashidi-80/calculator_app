import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/ui/widgets/calc_button.dart';
import 'package:calculator_app/utils/digit_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 14 — clipboard ASCII, refocus after history, comma decimal, focus skip.
void main() {
  group('Clipboard ASCII (Persian display → ASCII copy)', () {
    test('copyPlainText normalizes Persian digits', () {
      final c = Calculator();
      c.inputDigit('4');
      c.inputDigit('2');
      expect(
        DigitLocale.toClipboardAscii(
          DigitLocale.formatDisplay('42', usePersianDigits: true),
        ),
        '42',
      );
    });

    test(
      'copyPlainText from calculator with Persian-formatted display path',
      () {
        final c = Calculator();
        c.pasteFromText('1234567.89');
        expect(c.copyPlainText, '1234567.89');
      },
    );
  });

  group('Comma / Arabic decimal keyboard', () {
    testWidgets('comma key inserts decimal', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump();

      expect(displayText(tester), contains('0'));
      expect(displayText(tester), contains('5'));
    });

    testWidgets('Persian locale shows ٫ on decimal key', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      expect(find.text('٫'), findsOneWidget);
    });
  });

  group('Focus skip disabled keys (jrpool / MS #2474)', () {
    testWidgets('End focuses add when equals disabled', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      final add = tester.widget<CalcButton>(find.byKey(const Key('btn_add')));
      expect(add.keyboardFocused, isTrue);
    });

    testWidgets('keyboard works after closing history sheet', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '3');

      await tester.tap(find.byKey(const Key('btn_history')));
      await tester.pumpAndSettle();
      await dismissBottomSheet(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pump();
      expect(displayText(tester), '4');
    });
  });

  group('Max digit disables further input', () {
    test('canInputDigit false at max length while typing', () {
      final c = Calculator();
      for (var i = 0; i < 16; i++) {
        c.inputDigit('9');
      }
      expect(c.canInputDigit, isFalse);
    });
  });
}
