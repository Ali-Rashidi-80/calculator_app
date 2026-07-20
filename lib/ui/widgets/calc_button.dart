import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../calc_layout.dart';

enum CalcButtonKind { digit, operator, utility, equals }

class CalcButton extends StatefulWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.id,
    required this.onTap,
    this.onLongPress,
    this.kind = CalcButtonKind.digit,
    this.flex = 1,
    this.semanticsLabel,
    this.selected = false,
    this.keyboardFocused = false,
    this.touchEnabled = true,
    this.enabled = true,
    this.onTouchBlocked,
    this.enableHaptics = true,
  });

  final String label;
  final String id;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final CalcButtonKind kind;
  final int flex;
  final String? semanticsLabel;
  final bool selected;
  final bool keyboardFocused;
  final bool touchEnabled;
  final bool enabled;
  final VoidCallback? onTouchBlocked;
  final bool enableHaptics;

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _hovered = false;
  bool _pressed = false;
  DateTime? _lastTap;

  void _handleTap() {
    if (!widget.enabled) return;
    if (!widget.touchEnabled) {
      widget.onTouchBlocked?.call();
      return;
    }
    if (widget.kind != CalcButtonKind.equals) {
      final now = DateTime.now();
      if (_lastTap != null && now.difference(_lastTap!).inMilliseconds < 80) {
        return;
      }
      _lastTap = now;
    }
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap();
  }

  void _handleLongPress() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final calc = CalcTheme.of(context);

    Color bg;
    Color fg;
    switch (widget.kind) {
      case CalcButtonKind.operator:
        bg = calc.operatorColor;
        fg = calc.operatorOnColor;
      case CalcButtonKind.equals:
        bg = cs.primary;
        fg = cs.onPrimary;
      case CalcButtonKind.utility:
        bg = cs.secondaryContainer.withValues(alpha: 0.85);
        fg = cs.onSecondaryContainer;
      case CalcButtonKind.digit:
        bg = cs.surfaceContainerHigh.withValues(alpha: 0.9);
        fg = cs.onSurface;
    }

    if (_hovered && !_pressed) {
      bg = Color.lerp(bg, Colors.white, 0.08)!;
    }
    if (_pressed) {
      bg = Color.lerp(bg, Colors.black, 0.12)!;
    }
    if (!widget.enabled) {
      bg = Color.lerp(bg, cs.surface, 0.55)!;
      fg = fg.withValues(alpha: 0.38);
    }

    final layout = CalcLayout.of(context);
    final fontSize = layout.buttonFontSize;
    final pad = layout.buttonPadding;
    final highContrast = MediaQuery.highContrastOf(context);

    Border? buttonBorder;
    if (widget.selected) {
      buttonBorder = Border.all(color: cs.onPrimary, width: 2.5);
    } else if (widget.keyboardFocused) {
      buttonBorder = Border.all(color: cs.primary, width: 3);
    } else if (highContrast) {
      buttonBorder = Border.all(color: cs.outline, width: 2);
    }

    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = _pressed = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.enabled ? _handleTap : null,
            onLongPress:
                widget.enabled &&
                    widget.touchEnabled &&
                    widget.onLongPress != null
                ? _handleLongPress
                : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: layout.minTouchTarget,
                minWidth: layout.minTouchTarget,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: buttonBorder,
                  boxShadow: _pressed
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: _hovered ? 10 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Semantics(
                  button: true,
                  enabled: widget.enabled,
                  label: widget.semanticsLabel ?? widget.label,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
