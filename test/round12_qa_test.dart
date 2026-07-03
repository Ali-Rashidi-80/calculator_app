import 'package:calculator_app/calculator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 12 — Windows % chain, undo/redo, percent-after-clear (#2139).
void main() {
  group('Windows percent in chain (MS Standard)', () {
    test('50+10% shows 5 then equals 55', () {
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

    test('100+10% equals 110', () {
      final c = Calculator();
      c.inputDigit('1');
      c.inputDigit('0');
      c.inputDigit('0');
      c.setOperation('+');
      c.inputDigit('1');
      c.inputDigit('0');
      c.percent();
      c.equals();
      expect(c.display, '110');
    });

    test('200-10% equals 180', () {
      final c = Calculator();
      c.inputDigit('2');
      c.inputDigit('0');
      c.inputDigit('0');
      c.setOperation('-');
      c.inputDigit('1');
      c.inputDigit('0');
      c.percent();
      c.equals();
      expect(c.display, '180');
    });

    test('standalone percent still divides by 100', () {
      final c = Calculator();
      c.inputDigit('2');
      c.inputDigit('5');
      c.percent();
      expect(c.display, '0.25');
    });
  });

  group('Percent after clear (#2139 regression)', () {
    test('AC then 25% gives 0.25 not reset', () {
      final c = Calculator();
      c.inputDigit('9');
      c.inputDigit('9');
      c.clear();
      expect(c.display, '0');
      c.inputDigit('2');
      c.inputDigit('5');
      c.percent();
      expect(c.display, '0.25');
    });

    test('percent on zero after clear stays zero', () {
      final c = Calculator();
      c.clear();
      c.percent();
      expect(c.display, '0');
    });
  });

  group('Undo / redo (Kalkyl-style)', () {
    test('undo restores state before equals', () {
      final c = Calculator();
      c.inputDigit('2');
      c.inputDigit('5');
      c.setOperation('+');
      c.inputDigit('3');
      c.equals();
      expect(c.display, '28');
      c.undo();
      expect(c.display, '3');
      expect(c.pendingOp, '+');
    });

    test('redo reapplies equals', () {
      final c = Calculator();
      c.inputDigit('1');
      c.inputDigit('0');
      c.setOperation('+');
      c.inputDigit('5');
      c.equals();
      c.undo();
      c.redo();
      expect(c.display, '15');
    });

    test('undo after clear restores previous display', () {
      final c = Calculator();
      c.inputDigit('4');
      c.inputDigit('2');
      c.clear();
      expect(c.display, '0');
      c.undo();
      expect(c.display, '42');
    });

    test('canUndo false on fresh calculator', () {
      expect(Calculator().canUndo, isFalse);
    });
  });

  group('Keyboard undo shortcut', () {
    testWidgets('Ctrl+Z undoes last equals', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '3');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '15');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(displayText(tester), '3');
    });
  });
}
