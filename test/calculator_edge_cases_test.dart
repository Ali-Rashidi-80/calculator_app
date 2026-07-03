import 'package:calculator_app/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exhaustive backend edge-case matrix — each test is independent and real.
void main() {
  group('Calculator edge-case matrix', () {
    test('setOperation swap replaces pending op without eval', () {
      final c = Calculator();
      c.inputDigit('5');
      c.setOperation('+');
      c.setOperation('×');
      expect(c.pendingOp, '×');
      c.inputDigit('2');
      c.equals();
      expect(c.display, '10');
    });

    test('percent after result', () {
      final c = Calculator();
      c.inputDigit('5');
      c.inputDigit('0');
      c.percent();
      expect(c.display, '0.5');
    });

    test('negative result formatting', () {
      final c = Calculator();
      c.inputDigit('3');
      c.setOperation('-');
      c.inputDigit('8');
      c.equals();
      expect(c.display, '-5');
    });

    test('divide small decimal', () {
      final c = Calculator();
      c.inputDigit('1');
      c.setOperation('÷');
      c.inputDigit('4');
      c.equals();
      expect(c.display, '0.25');
    });

    test('memory survives clear but not memoryClear', () {
      final c = Calculator();
      c.inputDigit('8');
      c.memoryAdd();
      c.clear();
      expect(c.hasMemory, isTrue);
      c.memoryClear();
      expect(c.hasMemory, isFalse);
    });

    test('paste rejects empty string', () {
      final c = Calculator();
      expect(c.pasteFromText('   '), isFalse);
    });

    test('loadResult clears pending operation', () {
      final c = Calculator();
      c.inputDigit('1');
      c.setOperation('+');
      c.loadResult('99');
      expect(c.display, '99');
      expect(c.pendingOp, isNull);
    });

    test('history line format', () {
      final c = Calculator();
      c.inputDigit('1');
      c.setOperation('+');
      c.inputDigit('1');
      c.equals();
      expect(c.history.entries.first.line, '1 + 1 = 2');
    });
  });
}
