import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('Responsive layout (honest viewport tests)', () {
    final viewports = <String, Size>{
      'compact_320': const Size(320, 568),
      'phone_390': const Size(390, 844),
      'phone_landscape_667': const Size(667, 375),
      'tablet_768': const Size(768, 1024),
      'tablet_landscape_1024': const Size(1024, 768),
      'desktop_1280': const Size(1280, 800),
      'wide_1920': const Size(1920, 1080),
    };

    for (final entry in viewports.entries) {
      testWidgets('renders and calculates at ${entry.key}', (tester) async {
        setTestViewport(tester, entry.value);
        await pumpCalculatorApp(tester);

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('display')), findsOneWidget);
        expect(find.byKey(const Key('btn_eq')), findsOneWidget);

        await tapCalc(tester, '7');
        await tapCalc(tester, 'add');
        await tapCalc(tester, '3');
        await tapCalc(tester, 'eq');
        expect(displayText(tester), '10');
      });
    }

    testWidgets('wide desktop shows side history panel', (tester) async {
      setTestViewport(tester, const Size(1280, 900));
      await pumpCalculatorApp(tester);

      expect(find.byKey(const Key('history_list')), findsNothing);
      expect(find.text('History'), findsOneWidget);
      expect(find.byKey(const Key('btn_history')), findsNothing);
    });

    testWidgets('phone shows history button not side panel', (tester) async {
      setTestViewport(tester, const Size(390, 844));
      await pumpCalculatorApp(tester);

      expect(find.byKey(const Key('btn_history')), findsOneWidget);
    });
  });
}
