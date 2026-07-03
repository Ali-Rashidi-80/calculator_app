import 'package:calculator_app/main.dart';
import 'package:calculator_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared pump helper — resets prefs each test for honest isolation.
Future<void> pumpCalculatorApp(
  WidgetTester tester, {
  Map<String, Object>? prefs,
  Locale? locale,
  bool preservePrefs = false,
}) async {
  if (!preservePrefs) {
    SharedPreferences.setMockInitialValues(prefs ?? {});
  } else if (prefs != null) {
    SharedPreferences.setMockInitialValues(prefs);
  }
  final settings = await AppSettings.load();
  if (locale != null) {
    await settings.setLocale(locale);
  }
  await tester.pumpWidget(CalculatorApp(settings: settings));
  await tester.pumpAndSettle();
}

/// Simulates app relaunch while keeping SharedPreferences mock store intact.
Future<void> relaunchCalculatorApp(WidgetTester tester) async {
  final settings = await AppSettings.load();
  await tester.pumpWidget(CalculatorApp(settings: settings));
  await tester.pumpAndSettle();
}

void setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> tapCalc(WidgetTester tester, String keyId) async {
  await tester.tap(find.byKey(Key('btn_$keyId')));
  await tester.pump();
}

/// Closes a modal bottom sheet (drag down or scrim tap).
Future<void> dismissBottomSheet(WidgetTester tester) async {
  final sheet = find.byType(BottomSheet);
  if (sheet.evaluate().isNotEmpty) {
    final box = tester.getSize(sheet);
    final origin = tester.getTopLeft(sheet) + Offset(box.width / 2, 24);
    await tester.dragFrom(origin, const Offset(0, 800));
    await tester.pumpAndSettle();
    if (sheet.evaluate().isEmpty) return;
  }

  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tapAt(Offset(size.width / 2, 12));
  await tester.pumpAndSettle();
}

String displayText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('display'))).data!;
