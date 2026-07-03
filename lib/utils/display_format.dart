/// Display formatting helpers — snap IEEE-754 artifacts (0.1+0.2, 1÷3×3).
abstract final class DisplayFormat {
  static const _maxFractionDigits = 10;
  static const _baseEpsilon = 1e-9;

  /// Snaps values extremely close to a shorter decimal representation.
  static double snap(double value) {
    if (value.isNaN || value.isInfinite) return value;
    final tolerance = _baseEpsilon * (1 + value.abs());
    for (var digits = 0; digits <= _maxFractionDigits; digits++) {
      final candidate = double.parse(value.toStringAsFixed(digits));
      if ((value - candidate).abs() <= tolerance) {
        return candidate;
      }
    }
    return value;
  }

  static String formatPlain(double value) {
    final snapped = snap(value);
    if (snapped == snapped.roundToDouble()) {
      return snapped.toInt().toString();
    }
    final rounded = double.parse(snapped.toStringAsFixed(_maxFractionDigits));
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded
        .toStringAsFixed(8)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
