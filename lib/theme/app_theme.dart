import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF5C6BC0);
  static const _accent = Color(0xFFFFAB40);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      primary: const Color(0xFF3949AB),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      extensions: [
        CalcTheme(
          operatorColor: const Color(0xFFFF9800),
          operatorOnColor: const Color(0xFF1A1A1A),
          cardGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.95),
              scheme.surface.withValues(alpha: 0.9),
            ],
          ),
          backdropGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8EAF6), Color(0xFFF5F5F5), Color(0xFFE3F2FD)],
          ),
          cardBorderColor: Colors.black.withValues(alpha: 0.06),
          cardShadowColor: Colors.black.withValues(alpha: 0.12),
        ),
      ],
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      primary: const Color(0xFF7986CB),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      extensions: [
        CalcTheme(
          operatorColor: _accent,
          operatorOnColor: const Color(0xFF1A1A1A),
          cardGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              scheme.surface.withValues(alpha: 0.35),
            ],
          ),
          backdropGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF161B33), Color(0xFF1A237E)],
          ),
          cardBorderColor: Colors.white.withValues(alpha: 0.08),
          cardShadowColor: Colors.black.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

class CalcTheme extends ThemeExtension<CalcTheme> {
  const CalcTheme({
    required this.operatorColor,
    required this.operatorOnColor,
    required this.cardGradient,
    required this.backdropGradient,
    required this.cardBorderColor,
    required this.cardShadowColor,
  });

  final Color operatorColor;
  final Color operatorOnColor;
  final Gradient cardGradient;
  final Gradient backdropGradient;
  final Color cardBorderColor;
  final Color cardShadowColor;

  static CalcTheme of(BuildContext context) {
    return Theme.of(context).extension<CalcTheme>()!;
  }

  @override
  CalcTheme copyWith({
    Color? operatorColor,
    Color? operatorOnColor,
    Gradient? cardGradient,
    Gradient? backdropGradient,
    Color? cardBorderColor,
    Color? cardShadowColor,
  }) {
    return CalcTheme(
      operatorColor: operatorColor ?? this.operatorColor,
      operatorOnColor: operatorOnColor ?? this.operatorOnColor,
      cardGradient: cardGradient ?? this.cardGradient,
      backdropGradient: backdropGradient ?? this.backdropGradient,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
    );
  }

  @override
  CalcTheme lerp(ThemeExtension<CalcTheme>? other, double t) {
    if (other is! CalcTheme) return this;
    return CalcTheme(
      operatorColor: Color.lerp(operatorColor, other.operatorColor, t)!,
      operatorOnColor: Color.lerp(operatorOnColor, other.operatorOnColor, t)!,
      cardGradient: cardGradient,
      backdropGradient: backdropGradient,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t)!,
      cardShadowColor: Color.lerp(cardShadowColor, other.cardShadowColor, t)!,
    );
  }
}
