import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 6 — iOS swipe-delete, numpad desktop, persistence invariants.
void main() {
  group('Display swipe-left delete (iOS 18 regression lesson)', () {
    testWidgets('swipe left on display removes last digit', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, '2');
      await tapCalc(tester, '3');
      expect(displayText(tester), '123');

      await tester.drag(
        find.byKey(const Key('display_gesture')),
        const Offset(-80, 0),
      );
      await tester.pumpAndSettle();

      expect(displayText(tester), '12');
    });

    testWidgets('swipe left on single digit resets to zero', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '7');
      await tester.drag(
        find.byKey(const Key('display_gesture')),
        const Offset(-80, 0),
      );
      await tester.pumpAndSettle();

      expect(displayText(tester), '0');
    });
  });

  group('Desktop numpad keys (Pearson / Windows calc)', () {
    testWidgets('numpad multiply and enter evaluate', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadMultiply);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump();

      expect(displayText(tester), '12');
    });

    testWidgets('numpad add subtract divide chain', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadDivide);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump();
      expect(displayText(tester), '4');

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump();
      expect(displayText(tester), '10');
    });
  });

  group('Repeat equals still works (iOS 18.3 lesson)', () {
    testWidgets('triple equals repeats last multiply', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '2');
      await tapCalc(tester, 'mul');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '4');

      await tapCalc(tester, 'eq');
      expect(displayText(tester), '8');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '16');
    });
  });
}
