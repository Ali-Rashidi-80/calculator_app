/// Persian / Arabic digit and decimal separator normalization.
class DigitLocale {
  DigitLocale._();

  static const _persianZero = 0x06F0;
  static const _arabicIndicZero = 0x0660;

  /// Maps Eastern Arabic / Persian digits and decimal marks to ASCII calculator input.
  static String normalizeToAscii(String input) {
    final buf = StringBuffer();
    for (final code in input.runes) {
      if (code >= _persianZero && code <= _persianZero + 9) {
        buf.writeCharCode(0x30 + (code - _persianZero));
      } else if (code >= _arabicIndicZero && code <= _arabicIndicZero + 9) {
        buf.writeCharCode(0x30 + (code - _arabicIndicZero));
      } else if (code == 0x066B || code == 0x060C) {
        // Arabic decimal separator (٫) or Arabic comma (،)
        buf.write('.');
      } else if (code == 0x066C) {
        // Arabic thousands separator — strip for paste/input
        continue;
      } else if (code == 0x2212) {
        // Unicode minus (U+2212)
        buf.write('-');
      } else {
        buf.writeCharCode(code);
      }
    }
    return buf.toString();
  }

  /// Normalize pasted numbers: ASCII digits, locale-aware comma/dot rules (MS #2396).
  ///
  /// - Only `,` → last comma is decimal (`3,14` → `3.14`)
  /// - Only `.` → keep as decimal (`3.14`)
  /// - Both → last separator is decimal, earlier ones are thousands
  ///   (`1.234,56` → `1234.56`, `1,234.56` → `1234.56`)
  static String normalizePaste(String raw) {
    var s = normalizeToAscii(raw.trim());
    if (s.isEmpty) return s;

    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');

    if (lastDot < 0 && lastComma < 0) return s;

    if (lastComma >= 0 && lastDot < 0) {
      final before = s.substring(0, lastComma).replaceAll(',', '');
      final after = s.substring(lastComma + 1).replaceAll(',', '');
      return '$before.$after';
    }

    if (lastDot >= 0 && lastComma < 0) {
      // Keep last dot as decimal; strip earlier dots (thousands) if any.
      if ('.'.allMatches(s).length == 1) return s;
      final before = s.substring(0, lastDot).replaceAll('.', '');
      final after = s.substring(lastDot + 1).replaceAll('.', '');
      return '$before.$after';
    }

    // Both present: last separator wins as decimal.
    if (lastComma > lastDot) {
      final before = s
          .substring(0, lastComma)
          .replaceAll(',', '')
          .replaceAll('.', '');
      final after = s
          .substring(lastComma + 1)
          .replaceAll(',', '')
          .replaceAll('.', '');
      return '$before.$after';
    }

    final before = s
        .substring(0, lastDot)
        .replaceAll(',', '')
        .replaceAll('.', '');
    final after = s
        .substring(lastDot + 1)
        .replaceAll(',', '')
        .replaceAll('.', '');
    return '$before.$after';
  }

  static String toPersianDigits(String ascii) {
    if (ascii.isEmpty) return ascii;
    final buf = StringBuffer();
    for (final code in ascii.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buf.writeCharCode(_persianZero + (code - 0x30));
      } else {
        buf.writeCharCode(code);
      }
    }
    return buf.toString();
  }

  static String formatDisplay(String ascii, {required bool usePersianDigits}) {
    if (!usePersianDigits) return ascii;
    final withDigits = toPersianDigits(ascii);
    return withDigits.replaceAll('.', '\u066B');
  }

  /// ASCII plain text for clipboard (Persian digits + ٫ → 0-9 and `.`).
  static String toClipboardAscii(String display) {
    return normalizeToAscii(
      display,
    ).replaceAll('\u066B', '.').replaceAll(',', '.');
  }
}
