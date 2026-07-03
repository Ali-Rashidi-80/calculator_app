import 'package:calculator_app/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end logic flows — mirrors real UI sessions without widget shortcuts.
void main() {
  group('Calculator integration (backend flows)', () {
    test('multi-step session: add, multiply, percent', () {
      final c = Calculator();
      c.inputDigit('1');
      c.inputDigit('5');
      c.setOperation('+');
      c.inputDigit('2');
      c.inputDigit('5');
      c.equals();
      expect(c.display, '40');

      c.setOperation('×');
      c.inputDigit('2');
      c.equals();
      expect(c.display, '80');

      c.percent();
      expect(c.display, '0.8');
      expect(c.expression, isEmpty);
    });

    test('backspace then continue calculation', () {
      final c = Calculator();
      c.inputDigit('1');
      c.inputDigit('2');
      c.inputDigit('3');
      c.deleteLast();
      c.setOperation('+');
      c.inputDigit('7');
      c.equals();
      expect(c.display, '19');
    });

    test('sign toggle and decimal combine correctly', () {
      final c = Calculator();
      c.inputDigit('8');
      c.toggleSign();
      c.inputDecimal();
      c.inputDigit('5');
      expect(c.display, '-8.5');
    });

    test('clear after pending operation resets expression', () {
      final c = Calculator();
      c.inputDigit('9');
      c.setOperation('÷');
      expect(c.expression, '9 ÷');
      c.clear();
      expect(c.display, '0');
      expect(c.expression, isEmpty);
    });

    test('divide by zero then clear restores usable state', () {
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
  });
}
