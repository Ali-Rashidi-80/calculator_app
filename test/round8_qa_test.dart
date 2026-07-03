import 'package:calculator_app/calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 8 — Windows memory shortcuts, Delete=CE, F9 sign, resume focus, export valid.
void main() {
  group('Session export invariants (#2458)', () {
    test('exportSession is always valid snapshot', () {
      final c = Calculator();
      expect(c.exportSession().isValid, isTrue);

      c.inputDigit('1');
      c.setOperation('+');
      c.inputDigit('2');
      c.equals();
      expect(c.exportSession().isValid, isTrue);
      expect(c.exportSession().lastOp, '+');
      expect(c.exportSession().lastOperand, 2);

      c.memoryStore();
      expect(c.exportSession().isValid, isTrue);
    });

    test('memoryStore replaces memory value', () {
      final c = Calculator();
      c.inputDigit('8');
      c.memoryStore();
      c.clear();
      c.memoryRecall();
      expect(c.display, '8');
    });
  });

  group('Windows memory keyboard shortcuts', () {
    testWidgets('Ctrl+M store and Ctrl+R recall', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(find.byKey(const Key('memory_indicator')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(displayText(tester), '9');
    });

    testWidgets('Ctrl+P add and Ctrl+Q subtract memory', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(displayText(tester), '7');
    });
  });

  group('Delete and F9 (Windows standard shortcuts)', () {
    testWidgets('Delete clears entry only during pending op', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '9');
      expect(displayText(tester), '9');

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(displayText(tester), '0');
      expect(find.textContaining('12 +'), findsOneWidget);
    });

    testWidgets('F9 toggles sign on display', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pump();

      expect(displayText(tester), '-5');
    });
  });

  group('Resume lifecycle (#2118 lesson)', () {
    testWidgets('keyboard works after app resumed', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '4');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump();
      expect(displayText(tester), '42');
    });
  });
}
