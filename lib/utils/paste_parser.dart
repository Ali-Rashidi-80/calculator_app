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

    // Locale paste first (MS #2396) — allow `,` / mixed thousands before gate.
    if (!s.contains(RegExp(r'[+\-*/]'))) {
      final normalized = DigitLocale.normalizePaste(s);
      if (normalized.isEmpty) return (value: null, trimmed: false);
      if (!_allowedChars.hasMatch(normalized)) {
        return (value: null, trimmed: false);
      }
      var limited = normalized;
      final trimmed = _digitCount(limited) > maxPasteDigits;
      if (trimmed) {
        limited = _limitDigits(limited, maxPasteDigits);
      }
      final value = double.tryParse(limited);
      if (value == null || value.isNaN || value.isInfinite) {
        return (value: null, trimmed: false);
      }
      return (value: value, trimmed: trimmed);
    }

    // Expression path: normalize each numeric token (not the whole string).
    s = _normalizeExpressionSeparators(s);
    if (!_allowedChars.hasMatch(s)) return (value: null, trimmed: false);

    final value = _evaluateLtr(s);
    return (value: value, trimmed: false);
  }

  /// Apply [DigitLocale.normalizePaste] to each numeric token in an expression.
  static String _normalizeExpressionSeparators(String s) {
    final buf = StringBuffer();
    final token = StringBuffer();

    void flush() {
      if (token.isEmpty) return;
      buf.write(DigitLocale.normalizePaste(token.toString()));
      token.clear();
    }

    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if ('+-*/'.contains(c)) {
        if (c == '-' && token.isEmpty) {
          final soFar = buf.toString();
          if (soFar.isEmpty || '+-*/'.contains(soFar[soFar.length - 1])) {
            token.write(c);
            continue;
          }
        }
        flush();
        buf.write(c);
      } else {
        token.write(c);
      }
    }
    flush();
    return buf.toString();
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
