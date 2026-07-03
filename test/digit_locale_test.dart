import 'package:calculator_app/utils/digit_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DigitLocale', () {
    test('normalizes Persian digits to ASCII', () {
      expect(DigitLocale.normalizeToAscii('۱۲۳'), '123');
      expect(DigitLocale.normalizeToAscii('٤٥'), '45');
    });

    test('normalizes Arabic decimal separator', () {
      expect(DigitLocale.normalizePaste('۳٫۱۴'), '3.14');
    });

    test('normalizes unicode minus', () {
      expect(DigitLocale.normalizeToAscii('−5'), '-5');
    });

    test('formats display with Persian digits and decimal mark', () {
      expect(
        DigitLocale.formatDisplay('42', usePersianDigits: true),
        '۴۲',
      );
      expect(
        DigitLocale.formatDisplay('3.14', usePersianDigits: true),
        '۳٫۱۴',
      );
    });
  });
}
