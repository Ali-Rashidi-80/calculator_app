import 'package:calculator_app/calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 17 — memory/history SR labels, empty expr copy, refocus undo, Persian paste.
void main() {
  group('Memory bar accessibility (OpenCalc #405)', () {
    testWidgets('M+ button has localized tooltip in FA', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byKey(const Key('btn_m_add')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, 'جمع در حافظه (M+)');
    });

    testWidgets('memory indicator visible after M+', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '9');
      await tester.tap(find.byKey(const Key('btn_m_add')));
      await tester.pump();

      expect(find.byKey(const Key('memory_indicator')), findsOneWidget);
    });
  });

  group('Persian paste expression (MS #2114 + FA UX)', () {
    test('paste ۲×۳ evaluates to 6', () {
      final c = Calculator();
      expect(c.pasteFromText('۲×۳'), isTrue);
      expect(c.display, '6');
    });

    test('paste ۱۰:۲ equals 5', () {
      final c = Calculator();
      expect(c.pasteFromText('۱۰:۲'), isTrue);
      expect(c.display, '5');
    });
  });

  group('Empty expression copy (Ctrl+Shift+C)', () {
    testWidgets('shows hint when no pending expression', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No expression to copy'), findsOneWidget);
      expect(find.text('Copied'), findsNothing);
    });
  });

  group('Keyboard refocus after undo (MS #2447)', () {
    testWidgets('Ctrl+Z still works after equals', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '3');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '5');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(displayText(tester), '3');

      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pump();
      expect(displayText(tester), contains('4'));
    });
  });

  group('History entry semantics wiring', () {
    testWidgets('history tile exists after calculation on wide layout', (
      tester,
    ) async {
      setTestViewport(tester, const Size(1280, 900));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '2');
      await tapCalc(tester, 'eq');

      expect(find.byKey(const Key('history_list')), findsOneWidget);
      expect(find.textContaining('2 + 2'), findsWidgets);
    });
  });
}
