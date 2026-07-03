import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/utils/paste_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Round 20 — multiline paste, display context menu, Shift+Insert, memory/equals hints.
void main() {
  group('Multiline paste first line (NerdCalci #193)', () {
    test('uses first line only', () {
      expect(PasteParser.evaluate('42\n99'), 42);
    });

    test('calculator paste multiline', () {
      final c = Calculator();
      expect(c.pasteFromText('12\r\n34'), isTrue);
      expect(c.display, '12');
    });
  });

  group('Paste with history present (GrapheneOS #5358 inverse)', () {
    testWidgets('Ctrl+V works when history has entries', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return {'text': '99'};
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      setTestViewport(tester, const Size(1280, 900));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '1');
      await tapCalc(tester, 'eq');
      expect(find.byKey(const Key('history_list')), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(displayText(tester), '99');
    });
  });

  group('Shift+Insert paste (Windows standard)', () {
    testWidgets('Shift+Insert pastes from clipboard', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return {'text': '77'};
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(displayText(tester), '77');
    });
  });

  group('Memory empty feedback', () {
    testWidgets('Ctrl+R with empty memory shows hint', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Memory is empty'), findsOneWidget);
    });
  });

  group('Enter without pending equals', () {
    testWidgets('Enter on fresh display shows hint', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No calculation to complete'), findsOneWidget);
    });
  });

  group('Display copy/paste menu (GrapheneOS paste UX)', () {
    testWidgets('long-press on display shows copy and paste', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.longPress(find.byKey(const Key('display_gesture')));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
    });
  });
}
