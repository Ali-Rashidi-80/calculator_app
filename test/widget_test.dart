import 'package:calculator_app/main.dart';
import 'package:calculator_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final settings = await AppSettings.load();
    await tester.pumpWidget(CalculatorApp(settings: settings));
    await tester.pumpAndSettle();
  }

  testWidgets('calculator UI smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    expect(find.text('Calculator'), findsOneWidget);
    expect(find.byKey(const Key('display')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '0');

    await tester.tap(find.byKey(const Key('btn_7')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '7');

    await tester.tap(find.byKey(const Key('btn_add')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_eq')));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '10');
  });

  testWidgets('division by zero shows error', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_8')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_div')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_eq')));
    await tester.pump();

    expect(find.text('Cannot divide by zero'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, 'Cannot divide by zero');
  });

  testWidgets('clear button resets display', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_9')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_clear')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '0');
  });

  testWidgets('expression line shows pending operation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_add')));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('expression'))).data, '12 +');
  });

  testWidgets('keyboard digit updates display', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '4');
  });

  testWidgets('backspace button removes digit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_backspace')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '5');
  });

  testWidgets('percent button divides display by 100', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_pct')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '0.5');
  });

  testWidgets('keyboard minus and Enter evaluate expression', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '5');
  });

  testWidgets('keyboard Escape clears display', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '0');
  });

  testWidgets('sign button toggles display sign', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_sign')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '-5');
  });

  testWidgets('decimal button builds fractional display', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_dot')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_5')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '3.5');
  });

  testWidgets('multiply via keypad matches backend', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_mul')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_eq')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '42');
  });

  testWidgets('keyboard backspace removes digit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '1');
  });

  testWidgets('after divide-by-zero error next digit starts fresh', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_div')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_eq')));
    await tester.pump();
    expect(find.text('Cannot divide by zero'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_5')));
    await tester.pump();
    expect(find.text('Cannot divide by zero'), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '5');
  });

  testWidgets('repeat equals on keypad', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('btn_3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_add')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_eq')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '5');
    await tester.tap(find.byKey(const Key('btn_eq')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('display'))).data, '7');
  });
}
