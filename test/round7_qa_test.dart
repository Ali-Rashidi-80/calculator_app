import 'package:calculator_app/ui/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 7 — Pearson arrow grid, touch lock, Enter after history (#1810).
void main() {
  group('Arrow-key keypad navigation (Pearson a11y)', () {
    testWidgets('Home then Right focuses 8 with visible ring', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      final btn8 = tester.widget<CalcButton>(find.byKey(const Key('btn_8')));
      expect(btn8.keyboardFocused, isTrue);
    });

    testWidgets('Space on focused 7 enters digit', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(displayText(tester), '7');
    });

    testWidgets('End focuses equals when chain active', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '5');
      await tapCalc(tester, 'add');

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      final eq = tester.widget<CalcButton>(find.byKey(const Key('btn_eq')));
      expect(eq.keyboardFocused, isTrue);
    });
  });

  group('Enter after history (#1810 — not re-open history)', () {
    testWidgets('Enter repeats last op after closing history sheet', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '4');

      await tester.tap(find.byKey(const Key('btn_history')));
      await tester.pumpAndSettle();
      await dismissBottomSheet(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(displayText(tester), '6');
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('Touch lock (بازار pocket mode)', () {
    testWidgets('locked touch ignores tap but keyboard works', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, prefs: {'touch_lock': true});

      await tapCalc(tester, '9');
      expect(displayText(tester), '0');

      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump();
      expect(displayText(tester), '5');
    });
  });
}
