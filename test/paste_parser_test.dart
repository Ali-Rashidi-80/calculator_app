import 'package:calculator_app/utils/paste_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasteParser (MS #2114 aliases)', () {
    test('accepts multiply alias x', () {
      expect(PasteParser.evaluate('2 x 3'), 6);
    });

    test('accepts divide alias colon', () {
      expect(PasteParser.evaluate('8:2'), 4);
    });

    test('accepts bullet multiply', () {
      expect(PasteParser.evaluate('2•3'), 6);
    });

    test('LTR chain 2+3*4 equals 20', () {
      expect(PasteParser.evaluate('2+3*4'), 20);
    });

    test('unicode minus number', () {
      expect(PasteParser.evaluate('−12'), -12);
    });

    test('division by zero returns null', () {
      expect(PasteParser.evaluate('0/0'), isNull);
    });

    test('rejects garbage', () {
      expect(PasteParser.evaluate('not-a-number'), isNull);
    });
  });
}
