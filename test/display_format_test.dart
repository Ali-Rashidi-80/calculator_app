import 'package:calculator_app/utils/display_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisplayFormat snap', () {
    test('0.1 + 0.2 artifact snaps to 0.3', () {
      expect(DisplayFormat.formatPlain(0.1 + 0.2), '0.3');
    });

    test('1/3 * 3 artifact snaps to 1', () {
      expect(DisplayFormat.formatPlain(1 / 3 * 3), '1');
    });

    test('0.1 + 0.2 - 0.3 snaps to 0', () {
      expect(DisplayFormat.formatPlain(0.1 + 0.2 - 0.3), '0');
    });

    test('preserves meaningful fractions', () {
      expect(DisplayFormat.formatPlain(0.25), '0.25');
    });
  });
}
