import 'package:flutter/material.dart';

/// Responsive breakpoints for calculator UI (Material 3 + mobile-first).
///
/// Breakpoints: compact <360 · phone <600 · tablet ≥600 shortest ·
/// desktop ≥840 · side-history ≥900 · wide ≥1280
class CalcLayout {
  const CalcLayout(this.size);

  final Size size;

  static CalcLayout of(BuildContext context) =>
      CalcLayout(MediaQuery.sizeOf(context));

  double get width => size.width;
  double get height => size.height;
  double get shortestSide => size.shortestSide;

  bool get isCompact => width < 360;
  bool get isPhone => shortestSide < 600;
  bool get isTablet => shortestSide >= 600;
  bool get isDesktop => width >= 840;
  bool get isWideDesktop => width >= 1280;

  bool get isLandscapePhone => width > height && shortestSide < 600;

  /// Side-by-side history column (tablet landscape / desktop).
  bool get showSideHistory => width >= 900;

  /// Keyboard shortcuts button in app bar (desktop / wide layouts).
  bool get showKeyboardShortcutsButton => width >= 840;

  EdgeInsets get pagePadding {
    if (width >= 1280) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 12);
    }
    if (width >= 720) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 8);
    }
    if (width >= 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    return const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  }

  double get maxContentWidth {
    if (showSideHistory) return 960;
    if (width >= 840) return 480;
    if (width >= 600) return 440;
    return width;
  }

  double get maxContentHeight {
    final topInset = isCompact ? 96.0 : (isLandscapePhone ? 72.0 : 112.0);
    final available = height - topInset;
    if (showSideHistory) return available.clamp(480.0, 720.0);
    if (isLandscapePhone) return available.clamp(260.0, 380.0);
    if (isTablet) return available.clamp(480.0, 680.0);
    return available.clamp(380.0, 640.0);
  }

  /// WCAG / Material minimum touch target (48dp).
  double get minTouchTarget => 48;

  double get buttonFontSize {
    if (isLandscapePhone) return 20;
    if (width >= 600) return 26;
    if (width >= 360) return 22;
    return 20;
  }

  double get buttonPadding => 4;

  double get cardRadius => isCompact ? 22 : 28;
}
