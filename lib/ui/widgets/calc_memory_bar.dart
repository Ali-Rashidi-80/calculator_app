import 'package:flutter/material.dart';

import '../calc_rtl.dart';
import '../../l10n/app_localizations.dart';

class CalcMemoryBar extends StatelessWidget {
  const CalcMemoryBar({
    super.key,
    required this.hasMemory,
    required this.onAdd,
    required this.onSubtract,
    required this.onRecall,
    required this.onClear,
  });

  final bool hasMemory;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;
  final VoidCallback onRecall;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 14, 4),
      child: calcNumbersLtr(
        child: Row(
          children: [
            if (hasMemory)
              Semantics(
                label: l10n.semanticsMemoryActive,
                child: Container(
                  key: const Key('memory_indicator'),
                  margin: const EdgeInsetsDirectional.only(end: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.memoryIndicator,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            _MemBtn(
              key: const Key('btn_m_add'),
              label: 'M+',
              tooltip: l10n.memoryAdd,
              onTap: onAdd,
            ),
            _MemBtn(
              key: const Key('btn_m_sub'),
              label: 'M−',
              tooltip: l10n.memorySubtract,
              onTap: onSubtract,
            ),
            _MemBtn(
              key: const Key('btn_m_recall'),
              label: 'MR',
              tooltip: l10n.memoryRecall,
              onTap: onRecall,
              enabled: hasMemory,
            ),
            _MemBtn(
              key: const Key('btn_m_clear'),
              label: 'MC',
              tooltip: l10n.memoryClear,
              onTap: onClear,
              enabled: hasMemory,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemBtn extends StatelessWidget {
  const _MemBtn({
    super.key,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: enabled
          ? null
          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh.withValues(
            alpha: enabled ? 0.6 : 0.35,
          ),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onTap : null,
            child: Tooltip(
              message: tooltip,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(label, style: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
