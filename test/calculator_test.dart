import 'package:calculator_app/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calculator', () {
    late Calculator calc;

    setUp(() => calc = Calculator());

    test('starts at zero', () {
      expect(calc.display, '0');
    });

    test('adds digits', () {
      calc.inputDigit('1');
      calc.inputDigit('2');
      expect(calc.display, '12');
    });

    test('decimal input', () {
      calc.inputDigit('3');
      calc.inputDecimal();
      calc.inputDigit('5');
      expect(calc.display, '3.5');
    });

    test('basic addition chain', () {
      calc.inputDigit('2');
      calc.setOperation('+');
      calc.inputDigit('3');
      calc.equals();
      expect(calc.display, '5');
    });

    test('multiplication', () {
      calc.inputDigit('6');
      calc.setOperation('×');
      calc.inputDigit('7');
      calc.equals();
      expect(calc.display, '42');
    });

    test('division by zero throws', () {
      calc.inputDigit('8');
      calc.setOperation('÷');
      calc.inputDigit('0');
      expect(() => calc.equals(), throwsA(isA<CalculatorError>()));
    });

    test('clear resets state', () {
      calc.inputDigit('9');
      calc.clear();
      expect(calc.display, '0');
    });

    test('percent', () {
      calc.inputDigit('5');
      calc.inputDigit('0');
      calc.percent();
      expect(calc.display, '0.5');
    });

    test('expression shows pending operation', () {
      calc.inputDigit('1');
      calc.inputDigit('2');
      calc.setOperation('+');
      expect(calc.expression, '12 +');
    });

    test('subtraction', () {
      calc.inputDigit('9');
      calc.setOperation('-');
      calc.inputDigit('4');
      calc.equals();
      expect(calc.display, '5');
    });

    test('division', () {
      calc.inputDigit('8');
      calc.setOperation('÷');
      calc.inputDigit('2');
      calc.equals();
      expect(calc.display, '4');
    });

    test('deleteLast removes trailing digit', () {
      calc.inputDigit('1');
      calc.inputDigit('2');
      calc.inputDigit('3');
      calc.deleteLast();
      expect(calc.display, '12');
    });

    test('toggleSign negates display', () {
      calc.inputDigit('5');
      calc.toggleSign();
      expect(calc.display, '-5');
    });

    test('chained operations', () {
      calc.inputDigit('2');
      calc.setOperation('+');
      calc.inputDigit('3');
      calc.setOperation('×');
      calc.inputDigit('4');
      calc.equals();
      expect(calc.display, '20');
    });

    test('expression empty after equals', () {
      calc.inputDigit('3');
      calc.setOperation('+');
      calc.inputDigit('1');
      calc.equals();
      expect(calc.expression, isEmpty);
    });

    test('deleteLast on single digit resets to zero', () {
      calc.inputDigit('7');
      calc.deleteLast();
      expect(calc.display, '0');
    });

    test('decimal on fresh entry starts at 0.', () {
      calc.inputDecimal();
      expect(calc.display, '0.');
    });

    test('toggleSign on zero is no-op', () {
      calc.toggleSign();
      expect(calc.display, '0');
    });

    test('expression shows full line while entering second operand', () {
      calc.inputDigit('1');
      calc.inputDigit('2');
      calc.setOperation('+');
      calc.inputDigit('3');
      expect(calc.expression, '12 + 3');
    });

    test('division by zero in chained operation throws', () {
      calc.inputDigit('8');
      calc.setOperation('÷');
      calc.inputDigit('0');
      expect(() => calc.setOperation('+'), throwsA(isA<CalculatorError>()));
    });

    test('0.1 + 0.2 displays as 0.3', () {
      calc.inputDigit('0');
      calc.inputDecimal();
      calc.inputDigit('1');
      calc.setOperation('+');
      calc.inputDigit('0');
      calc.inputDecimal();
      calc.inputDigit('2');
      calc.equals();
      expect(calc.display, '0.3');
    });

    test('max digit length stops input', () {
      for (var i = 0; i < Calculator.maxDisplayLength + 2; i++) {
        calc.inputDigit('1');
      }
      expect(calc.display.replaceAll('.', '').replaceAll('-', '').length,
          lessThanOrEqualTo(Calculator.maxDisplayLength));
    });

    test('repeat equals applies last operation', () {
      calc.inputDigit('3');
      calc.setOperation('+');
      calc.inputDigit('2');
      calc.equals();
      expect(calc.display, '5');
      calc.equals();
      expect(calc.display, '7');
      calc.equals();
      expect(calc.display, '9');
    });

    test('history records completed calculation', () {
      calc.inputDigit('2');
      calc.setOperation('+');
      calc.inputDigit('2');
      calc.equals();
      expect(calc.history.entries.length, 1);
      expect(calc.history.entries.first.line, '2 + 2 = 4');
    });

    test('clear resets repeat state', () {
      calc.inputDigit('1');
      calc.setOperation('+');
      calc.inputDigit('1');
      calc.equals();
      calc.clear();
      calc.equals();
      expect(calc.display, '0');
    });

    test('pendingOp exposed for UI highlight', () {
      calc.inputDigit('5');
      calc.setOperation('×');
      expect(calc.pendingOp, '×');
      calc.equals();
      expect(calc.pendingOp, isNull);
    });

    test('deleteLast on fresh entry is no-op', () {
      calc.setOperation('+');
      calc.deleteLast();
      expect(calc.display, '0');
    });

    test('clearEntry resets display but keeps pending op', () {
      calc.inputDigit('1');
      calc.inputDigit('2');
      calc.setOperation('+');
      calc.inputDigit('3');
      calc.clearEntry();
      expect(calc.display, '0');
      expect(calc.pendingOp, '+');
      expect(calc.expression, '12 +');
    });

    test('memory add recall and clear', () {
      calc.inputDigit('5');
      calc.memoryAdd();
      expect(calc.hasMemory, isTrue);
      calc.clear();
      calc.memoryRecall();
      expect(calc.display, '5');
      calc.memoryClear();
      expect(calc.hasMemory, isFalse);
    });

    test('memory subtract', () {
      calc.inputDigit('1');
      calc.inputDigit('0');
      calc.memoryAdd();
      calc.clearEntry();
      calc.inputDigit('3');
      calc.memorySubtract();
      calc.clear();
      calc.memoryRecall();
      expect(calc.display, '7');
    });

    test('persian digit input', () {
      calc.inputDigit('۵');
      calc.inputDigit('۲');
      expect(calc.display, '52');
    });

    test('pasteFromText rejects invalid strings', () {
      expect(calc.pasteFromText('not-a-number'), isFalse);
    });

    test('pasteFromText accepts numeric strings', () {
      expect(calc.pasteFromText('  42.5  '), isTrue);
      expect(calc.display, '42.5');
    });

    test('pasteFromText accepts Persian decimal', () {
      expect(calc.pasteFromText('۱۲٫۵'), isTrue);
      expect(calc.display, '12.5');
    });

    test('loadResult from history entry', () {
      calc.loadResult('99');
      expect(calc.display, '99');
      expect(calc.expression, isEmpty);
    });

    test('clearHistory removes entries', () {
      calc.inputDigit('1');
      calc.setOperation('+');
      calc.inputDigit('1');
      calc.equals();
      expect(calc.history.entries, isNotEmpty);
      calc.clearHistory();
      expect(calc.history.isEmpty, isTrue);
    });

    test('deleteHistoryEntry by id', () {
      calc.inputDigit('2');
      calc.setOperation('×');
      calc.inputDigit('3');
      calc.equals();
      final id = calc.history.entries.first.id;
      expect(calc.deleteHistoryEntry(id), isTrue);
      expect(calc.history.isEmpty, isTrue);
    });

    test('scientific notation for very large numbers', () {
      calc.pasteFromText('10000000000');
      expect(calc.display, contains('e'));
    });

    test('session export and restore', () {
      calc.inputDigit('7');
      calc.setOperation('+');
      calc.inputDigit('3');
      calc.memoryAdd();
      final session = calc.exportSession();
      final mem = calc.memoryValue;

      final other = Calculator();
      other.restoreSession(session, memory: mem);
      expect(other.display, '3');
      expect(other.pendingOp, '+');
      expect(other.hasMemory, isTrue);
    });
  });
}
