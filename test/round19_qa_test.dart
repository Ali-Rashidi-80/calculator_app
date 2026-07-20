import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Round 19 — memory SR, undo/redo hints, settings fix, thousands paste, history persist.
void main() {
  group('Memory SR announcements (MS #2315)', () {
    testWidgets('Ctrl+M stores and shows memory indicator', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '4');
      await tapCalc(tester, '2');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(find.byKey(const Key('memory_indicator')), findsOneWidget);
    });
  });

  group('Undo/redo empty feedback', () {
    testWidgets('Ctrl+Z with nothing to undo shows hint', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Nothing to undo'), findsOneWidget);
    });
  });

  group('Settings restoreSession hint fix', () {
    testWidgets('restoreSession shows dedicated hint not swipe hint', (
      tester,
    ) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_settings')));
      await tester.pumpAndSettle();

      expect(
        find.text('Restore display and pending operation when reopening'),
        findsOneWidget,
      );
      expect(find.textContaining('Swipe down for history'), findsNothing);
    });
  });

  group('Persian thousands separator paste (بازار UX)', () {
    test('paste ۱٬۲۳۴ strips grouping', () {
      final c = Calculator();
      expect(c.pasteFromText('۱٬۲۳۴'), isTrue);
      expect(c.display, '1234');
    });
  });

  group('History persist default (#2392)', () {
    testWidgets('history survives relaunch with default settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      setTestViewport(tester, const Size(1280, 900));
      final settings = await AppSettings.load();
      expect(settings.persistHistory, isTrue);

      await tester.pumpWidget(CalculatorApp(settings: settings));
      await tester.pumpAndSettle();

      await tapCalc(tester, '5');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '5');
      await tapCalc(tester, 'eq');

      expect(find.byKey(const Key('history_list')), findsOneWidget);

      await relaunchCalculatorApp(tester);
      expect(find.byKey(const Key('history_list')), findsOneWidget);
      expect(find.textContaining('5 + 5'), findsWidgets);
    });
  });

  group('Settings keyboard hint discoverability (MS #1975)', () {
    testWidgets('settings sheet shows keyboard shortcuts', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_settings')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ctrl+Z'), findsOneWidget);
    });
  });
}
