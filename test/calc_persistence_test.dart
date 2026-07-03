import 'package:calculator_app/models/calc_history_entry.dart';
import 'package:calculator_app/services/calc_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('readSession rejects malformed snapshot', () async {
    SharedPreferences.setMockInitialValues({
      'calc_session_v1': '{"display":"","accumulator":null}',
    });
    final p = await CalcPersistence.load();
    expect(p.readSession(), isNull);
  });

  test('readSession accepts valid snapshot', () async {
    SharedPreferences.setMockInitialValues({
      'calc_session_v1': '{"display":"42","freshEntry":true}',
    });
    final p = await CalcPersistence.load();
    expect(p.readSession()?.display, '42');
  });

  test('readSession sanitizes invalid pending op to null', () async {
    SharedPreferences.setMockInitialValues({
      'calc_session_v1': '{"display":"5","pendingOp":"^"}',
    });
    final p = await CalcPersistence.load();
    expect(p.readSession()?.pendingOp, isNull);
    expect(p.readSession()?.display, '5');
  });

  test('readSession rejects lastOp without lastOperand', () async {
    SharedPreferences.setMockInitialValues({
      'calc_session_v1': '{"display":"2","lastOp":"+"}',
    });
    final p = await CalcPersistence.load();
    expect(p.readSession(), isNull);
  });

  test('readSession rejects pendingOp without accumulator', () async {
    SharedPreferences.setMockInitialValues({
      'calc_session_v1': '{"display":"5","pendingOp":"+"}',
    });
    final p = await CalcPersistence.load();
    expect(p.readSession(), isNull);
  });

  test('write and read history round-trip', () async {
    final p = await CalcPersistence.load();
    final entries = [
      CalcHistoryEntry(
        id: '1',
        expression: '1 + 1',
        result: '2',
        at: DateTime(2026, 1, 1),
      ),
    ];
    await p.writeHistory(entries);
    final read = p.readHistory();
    expect(read.length, 1);
    expect(read.first.result, '2');
  });

  test('clearAll removes stored keys', () async {
    SharedPreferences.setMockInitialValues({
      'calc_session_v1': '{"display":"9"}',
      'calc_memory_v1': 5.0,
      'calc_history_v1': '[]',
    });
    final p = await CalcPersistence.load();
    await p.clearAll();
    expect(p.readSession(), isNull);
    expect(p.readMemory(), isNull);
    expect(p.readHistory(), isEmpty);
  });
}
