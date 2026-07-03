import 'package:flutter/material.dart';

/// Dialog / sheet header with title centered and close on the visual right.
class CalcDialogHeader extends StatelessWidget {
  const CalcDialogHeader({
    super.key,
    required this.title,
    this.icon,
    this.onClose,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final closeOnRight = isRtl
        ? AlignmentDirectional.topStart
        : AlignmentDirectional.topEnd;

    return SizedBox(
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: closeOnRight,
            child: IconButton(
              key: const Key('dialog_close'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose ?? () => Navigator.maybePop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
