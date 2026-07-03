import 'package:calculator_app/calc_history.dart';
import 'package:calculator_app/models/calc_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalcHistory', () {
    late CalcHistory history;

    setUp(() => history = CalcHistory());

    test('starts empty', () {
      expect(history.isEmpty, isTrue);
    });

    test('add prepends newest first', () {
      history.add('1 + 1', '2');
      history.add('2 + 2', '4');
      expect(history.entries.first.result, '4');
      expect(history.entries.last.result, '2');
    });

    test('skips consecutive duplicate expression+result', () {
      history.add('1 + 1', '2');
      history.add('1 + 1', '2');
      expect(history.entries.length, 1);
    });

    test('caps at maxEntries', () {
      for (var i = 0; i < CalcHistory.maxEntries + 5; i++) {
        history.add('$i', '$i');
      }
      expect(history.entries.length, CalcHistory.maxEntries);
    });

    test('loadEntries respects cap', () {
      final saved = List.generate(
        120,
        (i) => CalcHistoryEntry(
          id: '$i',
          expression: '$i',
          result: '$i',
          at: DateTime.now(),
        ),
      );
      history.loadEntries(saved);
      expect(history.entries.length, CalcHistory.maxEntries);
    });

    test('removeById removes entry', () {
      history.add('1+1', '2');
      final id = history.entries.first.id;
      expect(history.removeById(id), isTrue);
      expect(history.isEmpty, isTrue);
    });

    test('removeById returns false for unknown id', () {
      expect(history.removeById('missing'), isFalse);
    });

    test('clear removes all', () {
      history.add('1', '1');
      history.clear();
      expect(history.isEmpty, isTrue);
    });
  });
}
