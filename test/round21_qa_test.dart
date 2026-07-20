import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 21 — settings modal width + readable keyboard shortcuts.
void main() {
  group('Settings modal width (desktop dialog)', () {
    testWidgets('opens as Dialog at 1280px', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_settings')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Keyboard shortcuts UX', () {
    testWidgets('desktop shows keyboard icon not long one-liner', (
      tester,
    ) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      expect(find.byKey(const Key('btn_keyboard_shortcuts')), findsOneWidget);
      expect(find.textContaining('Ctrl+Shift+D'), findsNothing);
    });

    testWidgets('keyboard dialog opens grouped shortcuts', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_keyboard_shortcuts')));
      await tester.pumpAndSettle();

      expect(find.text('Keyboard shortcuts'), findsOneWidget);
      expect(find.byKey(const Key('dialog_close')), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.textContaining('Ctrl+Z'), findsOneWidget);
    });

    testWidgets('settings sheet shows grouped shortcuts', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_settings')));
      await tester.pumpAndSettle();

      expect(find.text('Navigate'), findsOneWidget);
      expect(find.textContaining('Ctrl+M store'), findsOneWidget);
    });
  });
}
