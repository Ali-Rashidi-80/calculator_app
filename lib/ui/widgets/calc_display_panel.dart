import 'package:flutter/material.dart';
import '../../utils/digit_locale.dart';
import '../calc_rtl.dart';

class CalcDisplayPanel extends StatelessWidget {
  const CalcDisplayPanel({
    super.key,
    required this.display,
    required this.expression,
    this.runningTotal,
    this.error,
    this.onBackspace,
    this.onCopy,
    this.onPaste,
    this.onSwipeDown,
    this.usePersianDigits = false,
    this.runningTotalLabel,
    this.displayResultLabel,
    this.displayErrorLabel,
    this.backspaceLabel,
    this.copyLabel,
    this.pasteLabel,
    this.canBackspace = true,
  });

  final String display;
  final String expression;
  final String? runningTotal;
  final String? error;
  final VoidCallback? onBackspace;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onSwipeDown;
  final bool usePersianDigits;
  final String Function(String total)? runningTotalLabel;
  final String Function(String value)? displayResultLabel;
  final String Function(String message)? displayErrorLabel;
  final String? backspaceLabel;
  final String? copyLabel;
  final String? pasteLabel;
  final bool canBackspace;

  String _fmt(String s) =>
      DigitLocale.formatDisplay(s, usePersianDigits: usePersianDigits);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = error != null;
    final width = MediaQuery.sizeOf(context).width;
    final shown = isError ? error! : _fmt(display);
    final exprShown = _fmt(expression);
    final runningShown =
        runningTotal != null ? _fmt(runningTotal!) : null;

    final displayStyle = theme.textTheme.displayLarge?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      fontSize: width > 600 ? 56 : width > 360 ? 44 : 36,
      color: isError ? theme.colorScheme.error : theme.colorScheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 4),
      child: calcNumbersLtr(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        exprShown,
                        key: const Key('expression'),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (runningShown != null) ...[
                      const SizedBox(height: 2),
                      Semantics(
                        label: runningTotalLabel?.call(runningShown) ??
                            'Running total: $runningShown',
                        child: Text(
                          runningShown,
                          key: const Key('running_total'),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onBackspace != null)
                Semantics(
                  button: true,
                  enabled: canBackspace,
                  label: backspaceLabel ?? 'Backspace',
                  child: IconButton(
                    key: const Key('btn_backspace'),
                    tooltip: backspaceLabel ?? 'Backspace',
                    onPressed: canBackspace ? onBackspace : null,
                    icon: Icon(
                      Icons.backspace_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _DisplaySwipeArea(
              onBackspace: onBackspace,
              onCopy: onCopy,
              onPaste: onPaste,
              onSwipeDown: onSwipeDown,
              copyLabel: copyLabel,
              pasteLabel: pasteLabel,
              isError: isError,
              shown: shown,
              displayStyle: displayStyle,
              semanticsLabel: isError
                  ? (displayErrorLabel?.call(error!) ??
                      'Error: ${error!}')
                  : (displayResultLabel?.call(shown) ?? 'Result: $shown'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Swipe-left deletes a digit; swipe-down opens history (iOS / Google UX).
class _DisplaySwipeArea extends StatefulWidget {
  const _DisplaySwipeArea({
    required this.shown,
    required this.isError,
    required this.displayStyle,
    required this.semanticsLabel,
    this.onBackspace,
    this.onCopy,
    this.onPaste,
    this.onSwipeDown,
    this.copyLabel,
    this.pasteLabel,
  });

  final String shown;
  final bool isError;
  final TextStyle? displayStyle;
  final String semanticsLabel;
  final VoidCallback? onBackspace;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onSwipeDown;
  final String? copyLabel;
  final String? pasteLabel;

  @override
  State<_DisplaySwipeArea> createState() => _DisplaySwipeAreaState();
}

class _DisplaySwipeAreaState extends State<_DisplaySwipeArea> {
  double _horizontalDrag = 0;
  double _verticalDrag = 0;

  Future<void> _showCopyPasteMenu(Offset globalPosition) async {
    final onCopy = widget.onCopy;
    final onPaste = widget.onPaste;
    if (onCopy == null && onPaste == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      items: [
        if (onCopy != null)
          PopupMenuItem(
            value: 'copy',
            child: Text(widget.copyLabel ?? 'Copy'),
          ),
        if (onPaste != null)
          PopupMenuItem(
            value: 'paste',
            child: Text(widget.pasteLabel ?? 'Paste'),
          ),
      ],
    );

    if (!mounted) return;
    switch (action) {
      case 'copy':
        onCopy?.call();
      case 'paste':
        onPaste?.call();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('display_gesture'),
      behavior: HitTestBehavior.opaque,
      onDoubleTap: widget.onCopy,
      onLongPressStart: (details) =>
          _showCopyPasteMenu(details.globalPosition),
      onSecondaryTapDown: (details) =>
          _showCopyPasteMenu(details.globalPosition),
      onHorizontalDragStart: widget.onBackspace == null
          ? null
          : (_) => _horizontalDrag = 0,
      onHorizontalDragUpdate: widget.onBackspace == null
          ? null
          : (details) => _horizontalDrag += details.primaryDelta ?? 0,
      onHorizontalDragEnd: widget.onBackspace == null
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_horizontalDrag < -48 || velocity < -280) {
                widget.onBackspace!();
              }
              _horizontalDrag = 0;
            },
      onVerticalDragStart: widget.onSwipeDown == null
          ? null
          : (_) => _verticalDrag = 0,
      onVerticalDragUpdate: widget.onSwipeDown == null
          ? null
          : (details) => _verticalDrag += details.primaryDelta ?? 0,
      onVerticalDragEnd: widget.onSwipeDown == null
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_verticalDrag > 48 || velocity > 280) {
                widget.onSwipeDown!();
              }
              _verticalDrag = 0;
            },
      child: Semantics(
        label: widget.semanticsLabel,
        value: widget.shown,
        liveRegion: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            widget.shown,
            key: const Key('display'),
            textAlign: TextAlign.end,
            maxLines: 2,
            style: widget.displayStyle,
          ),
        ),
      ),
    );
  }
}
