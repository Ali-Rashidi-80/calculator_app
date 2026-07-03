import 'digit_locale.dart';

/// Parses pasted numbers and simple left-to-right expressions (MS #2114 aliases).
abstract final class PasteParser {
  static const int maxPasteDigits = 16;

  /// Result of parsing pasted text.
  static ({double? value, bool trimmed}) evaluateDetailed(String raw) {
    var s = DigitLocale.normalizeToAscii(raw.trim());
    if (s.isEmpty) return (value: null, trimmed: false);

    // First line only — NerdCalci #193 / SwiftKey multiline paste.
    if (s.contains('\n') || s.contains('\r')) {
      s = s.split(RegExp(r'[\r\n]+')).first.trim();
      if (s.isEmpty) return (value: null, trimmed: false);
    }

    s = s
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('•', '*')
        .replaceAll('·', '*')
        .replaceAll('x', '*')
        .replaceAll('X', '*')
        .replaceAll(':', '/')
        .replaceAll(' ', '');

    if (!_allowedChars.hasMatch(s)) return (value: null, trimmed: false);

    if (!s.contains(RegExp(r'[+\-*/]'))) {
      final trimmed = _digitCount(s) > maxPasteDigits;
      if (trimmed) {
        s = _limitDigits(s, maxPasteDigits);
      }
      final single = DigitLocale.normalizePaste(s);
      if (single.isEmpty) return (value: null, trimmed: false);
      final value = double.tryParse(single);
      if (value == null || value.isNaN || value.isInfinite) {
        return (value: null, trimmed: false);
      }
      return (value: value, trimmed: trimmed);
    }

    final value = _evaluateLtr(s);
    return (value: value, trimmed: false);
  }

  static double? evaluate(String raw) => evaluateDetailed(raw).value;

  static int _digitCount(String s) =>
      s.replaceAll(RegExp(r'[^0-9]'), '').length;

  /// Trim digit characters while preserving sign and decimal point (MS #162).
  static String _limitDigits(String s, int maxDigits) {
    final buf = StringBuffer();
    var digits = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '-' && buf.isEmpty) {
        buf.write(c);
        continue;
      }
      if (c == '.') {
        buf.write(c);
        continue;
      }
      if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        if (digits >= maxDigits) continue;
        digits++;
        buf.write(c);
      }
    }
    var out = buf.toString();
    if (out == '-' || out == '-.' || out == '.') return '0';
    return out;
  }

  static final _allowedChars = RegExp(r'^[\d.eE+\-*/.]+$');

  static double? _evaluateLtr(String s) {
    final parts = <String>[];
    final buf = StringBuffer();

    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if ('+-*/'.contains(c)) {
        if (buf.isEmpty) {
          if (c == '-') {
            buf.write(c);
            continue;
          }
          return null;
        }
        parts.add(buf.toString());
        parts.add(c);
        buf.clear();
      } else {
        buf.write(c);
      }
    }

    if (buf.isEmpty) return null;
    parts.add(buf.toString());

    if (parts.length == 1) {
      return double.tryParse(parts[0]);
    }

    if (parts.length.isEven) return null;

    final first = double.tryParse(parts[0]);
    if (first == null) return null;
    var acc = first;

    for (var i = 1; i < parts.length; i += 2) {
      if (i + 1 >= parts.length) return null;
      final op = parts[i];
      final b = double.tryParse(parts[i + 1]);
      if (b == null) return null;

      final next = switch (op) {
        '+' => acc + b,
        '-' => acc - b,
        '*' => acc * b,
        '/' => acc / b,
        _ => double.nan,
      };
      if (next.isNaN) return null;
      acc = next;
    }

    return acc.isNaN ? null : acc;
  }
}
