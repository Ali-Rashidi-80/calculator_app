import 'package:calculator_app/calculator.dart';
import 'package:calculator_app/services/calc_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end backend session covering every major feature path.
void main() {
  group('Full calculator session (all features)', () {
    test('calculate → history → memory → repeat → clear → restore', () {
      final c = Calculator();

      // Basic calc + history
      c.inputDigit('9');
      c.setOperation('-');
      c.inputDigit('4');
      c.equals();
      expect(c.display, '5');
      expect(c.history.entries.length, 1);

      // Repeat equals
      c.equals();
      expect(c.display, '1');

      // Memory
      c.memoryAdd();
      expect(c.hasMemory, isTrue);
      c.clear();
      c.memoryRecall();
      expect(c.display, '1');

      // CE keeps pending op
      c.setOperation('+');
      c.inputDigit('2');
      c.clearEntry();
      expect(c.display, '0');
      expect(c.pendingOp, '+');

      // Paste
      c.clear();
      expect(c.pasteFromText('12.5'), isTrue);
      expect(c.display, '12.5');

      // Session round-trip
      final session = c.exportSession();
      final mem = c.memoryValue;
      final hist = List.of(c.history.entries);

      final c2 = Calculator();
      c2.restoreSession(session, memory: mem);
      c2.loadHistory(hist);
      expect(c2.display, '12.5');
      expect(c2.hasMemory, isTrue);
      expect(c2.history.entries.length, 2);

      // History delete
      final id = c2.history.entries.first.id;
      expect(c2.deleteHistoryEntry(id), isTrue);
      expect(c2.history.entries.length, 1);

      // Clear all state
      c2.clear();
      c2.clearHistory();
      c2.memoryClear();
      expect(c2.display, '0');
      expect(c2.history.isEmpty, isTrue);
      expect(c2.hasMemory, isFalse);
    });

    test('chained LTR matches Windows behavior 2+3×4=20', () {
      final c = Calculator();
      c.inputDigit('2');
      c.setOperation('+');
      c.inputDigit('3');
      c.setOperation('×');
      c.inputDigit('4');
      c.equals();
      expect(c.display, '20');
    });

    test('error path clears and allows recovery', () {
      final c = Calculator();
      c.inputDigit('1');
      c.setOperation('÷');
      c.inputDigit('0');
      expect(() => c.equals(), throwsA(isA<CalculatorError>()));
      c.clear();
      c.inputDigit('6');
      c.setOperation('×');
      c.inputDigit('7');
      c.equals();
      expect(c.display, '42');
    });

    test('exportSession after clear is zero state', () {
      final c = Calculator();
      c.inputDigit('9');
      c.clear();
      final s = c.exportSession();
      expect(s.display, '0');
      expect(s.pendingOp, isNull);
      expect(s.accumulator, isNull);
    });
  });

  group('CalculatorSession validation', () {
    test('invalid session rejected', () {
      const bad = CalculatorSession(display: '');
      expect(bad.isValid, isFalse);
    });

    test('valid session accepted', () {
      const ok = CalculatorSession(display: '42', freshEntry: true);
      expect(ok.isValid, isTrue);
    });
  });
}
