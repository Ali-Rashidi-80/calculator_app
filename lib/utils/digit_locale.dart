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

  /// Normalize pasted numbers: ASCII digits, comma/dot decimal rules.
  static String normalizePaste(String raw) {
    var s = normalizeToAscii(raw.trim());
    if (s.isEmpty) return s;

    final hasDot = s.contains('.');
    final hasComma = s.contains(',');

    if (hasComma && !hasDot) {
      // "3,14" or "1.234,56" after normalize — treat last comma as decimal
      final lastComma = s.lastIndexOf(',');
      final before = s.substring(0, lastComma).replaceAll(',', '');
      final after = s.substring(lastComma + 1);
      s = '$before.$after';
    } else {
      s = s.replaceAll(',', '');
    }
    return s;
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
    return normalizeToAscii(display)
        .replaceAll('\u066B', '.')
        .replaceAll(',', '.');
  }
}
