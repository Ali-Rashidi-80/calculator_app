import 'package:calculator_app/ui/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Round 5 — honest QA: focus, persistence lifecycle, settings, edge cases.
void main() {
  group('Keyboard focus reliability (#1947 / #2448 lesson)', () {
    testWidgets('keyboard works after closing history sheet', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '1');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '1');
      await tapCalc(tester, 'eq');

      await tester.tap(find.byKey(const Key('btn_history')));
      await tester.pumpAndSettle();
      await dismissBottomSheet(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pump();
      expect(displayText(tester), '8');
    });

    testWidgets('keyboard works after closing settings sheet', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tester.tap(find.byKey(const Key('btn_settings')));
      await tester.pumpAndSettle();
      await dismissBottomSheet(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.pump();
      expect(displayText(tester), '6');
    });

    testWidgets('Escape clears and keyboard still accepts digits', (tester) async {
      setTestViewport(tester, const Size(1280, 800));
      await pumpCalculatorApp(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(displayText(tester), '0');

      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pump();
      expect(displayText(tester), '4');
    });
  });

  group('Persistence lifecycle (honest SharedPreferences)', () {
    testWidgets('session restores on relaunch when restoreSession enabled',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      setTestViewport(tester, const Size(390, 844));

      await pumpCalculatorApp(tester);
      await tapCalc(tester, '7');
      await tapCalc(tester, 'add');
      await tapCalc(tester, '3');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '10');
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      await relaunchCalculatorApp(tester);
      expect(displayText(tester), '10');
    });

    testWidgets('restoreSession off ignores saved display', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(
        tester,
        prefs: {
          'calc_session_v1': '{"display":"99","freshEntry":true}',
          'restore_session': false,
        },
      );
      expect(displayText(tester), '0');
    });

    testWidgets('clear persists zero session on relaunch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      setTestViewport(tester, const Size(390, 844));

      await pumpCalculatorApp(tester);
      await tapCalc(tester, '9');
      await tapCalc(tester, 'clear');
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      await relaunchCalculatorApp(tester);
      expect(displayText(tester), '0');
    });
  });

  group('Wide layout integration', () {
    testWidgets('side history reuse loads result into display', (tester) async {
      setTestViewport(tester, const Size(1280, 900));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '4');
      await tapCalc(tester, 'mul');
      await tapCalc(tester, '5');
      await tapCalc(tester, 'eq');
      expect(displayText(tester), '20');

      await tapCalc(tester, 'clear');
      expect(displayText(tester), '0');

      await tester.tap(find.textContaining('4 × 5'));
      await tester.pump();
      expect(displayText(tester), '20');
    });
  });

  group('Operator and chain UX', () {
    testWidgets('pending operator highlights add button', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      await tapCalc(tester, '2');
      await tapCalc(tester, 'add');
      final addBtn = tester.widget<CalcButton>(find.byKey(const Key('btn_add')));
      expect(addBtn.selected, isTrue);
    });
  });
}
