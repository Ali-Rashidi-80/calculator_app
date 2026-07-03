import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 22 — Persian RTL layout polish.
void main() {
  group('Persian RTL chrome', () {
    testWidgets('toolbar icons on right (leading) in fa locale', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      expect(find.byKey(const Key('btn_settings')), findsOneWidget);

      final settingsCenter =
          tester.getCenter(find.byKey(const Key('btn_settings')));
      expect(settingsCenter.dx, greaterThan(640));
    });

    testWidgets('memory buttons align to display right edge', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      final mc = tester.getTopRight(find.byKey(const Key('btn_m_clear')));
      final display = tester.getTopRight(find.byKey(const Key('display')));
      expect(mc.dx, closeTo(display.dx, 48));
    });

    testWidgets('backspace sits top-right of display row', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      await tapCalc(tester, '1');

      final backspace = tester.getTopRight(find.byKey(const Key('btn_backspace')));
      final display = tester.getTopRight(find.byKey(const Key('display_gesture')));
      expect(backspace.dx, greaterThanOrEqualTo(display.dx - 8));
    });

    testWidgets('desktop keeps calculator on the right panel', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      final calcCenter = tester.getCenter(find.byKey(const Key('btn_eq')));
      expect(calcCenter.dx, greaterThan(640));
    });

    testWidgets('history header is right-aligned in fa', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      final titleRect = tester.getRect(find.text('تاریخچه'));
      expect(titleRect.right, greaterThan(420));
    });

    testWidgets('dialog close on visual right in fa', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      await tester.tap(find.byKey(const Key('btn_keyboard_shortcuts')));
      await tester.pumpAndSettle();

      final close = tester.getTopRight(find.byKey(const Key('dialog_close')));
      expect(close.dx, greaterThan(640));
    });
  });
}
