import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/utils/paste_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 18 — empty clipboard, paste trim MS #162, invalid paste SR, app bar a11y.
void main() {
  group('Paste trim long numbers (MS #162)', () {
    test('trims single number beyond 16 digits', () {
      final parsed = PasteParser.evaluateDetailed(
        '123456789012345678901234567890',
      );
      expect(parsed.trimmed, isTrue);
      expect(parsed.value, isNotNull);
    });

    test('calculator paste sets lastPasteTrimmed', () {
      final c = Calculator();
      expect(
        c.pasteFromText('123456789012345678901234567890'),
        isTrue,
      );
      expect(c.lastPasteTrimmed, isTrue);
    });

    test('does not trim expressions', () {
      final parsed = PasteParser.evaluateDetailed('1234567890123456+1');
      expect(parsed.trimmed, isFalse);
      expect(parsed.value, 1234567890123457);
    });
  });

  group('Spaced paste expression (MS #2114)', () {
    test('paste 2 + 3 evaluates to 5', () {
      final c = Calculator();
      expect(c.pasteFromText('2 + 3'), isTrue);
      expect(c.display, '5');
    });
  });

  group('Empty clipboard paste (UX StackExchange)', () {
    testWidgets('Ctrl+V with empty clipboard shows hint', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return null;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Clipboard is empty'), findsOneWidget);
    });
  });

  group('Invalid paste feedback', () {
    test('pasteFromText rejects garbage', () {
      final c = Calculator();
      expect(c.pasteFromText('not-a-number'), isFalse);
      expect(c.lastPasteTrimmed, isFalse);
    });
  });

  group('App bar accessibility', () {
    testWidgets('history button has tooltip in FA', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester, locale: const Locale('fa'));

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byKey(const Key('btn_history')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, 'تاریخچه');
    });
  });

  group('Settings refocus (#2448)', () {
    testWidgets('keyboard works after closing settings', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_settings')));
      await tester.pumpAndSettle();
      await dismissBottomSheet(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
      await tester.pump();
      expect(displayText(tester), '7');
    });
  });
}
