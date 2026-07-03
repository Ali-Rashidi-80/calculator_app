import 'package:flutter/material.dart';

import '../calc_rtl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/calc_history_entry.dart';

class CalcHistoryPanel extends StatelessWidget {
  const CalcHistoryPanel({
    super.key,
    required this.entries,
    required this.onClear,
    required this.onReuse,
    required this.onDelete,
    this.onExport,
    this.onCopyResult,
    this.compact = false,
  });

  final List<CalcHistoryEntry> entries;
  final VoidCallback onClear;
  final ValueChanged<CalcHistoryEntry> onReuse;
  final ValueChanged<CalcHistoryEntry> onDelete;
  final VoidCallback? onExport;
  final ValueChanged<String>? onCopyResult;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isRtl = calcIsRtl(context);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(compact ? 20 : 24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 8),
              child: Row(
                textDirection:
                    isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Icon(Icons.history,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.history,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (entries.isNotEmpty) ...[
                    if (onExport != null)
                      Semantics(
                        button: true,
                        label: l10n.exportHistory,
                        child: IconButton(
                          key: const Key('btn_export_history'),
                          tooltip: l10n.exportHistory,
                          onPressed: onExport,
                          icon: const Icon(Icons.upload_outlined),
                        ),
                      ),
                    TextButton(
                      onPressed: onClear,
                      child: Semantics(
                        button: true,
                        label: l10n.clearHistory,
                        child: Text(l10n.clearHistory),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
              child: Text(
                l10n.tapToCopyHistory,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.historyEmpty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      key: const Key('history_list'),
                      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _HistoryTile(
                          entry: entry,
                          onReuse: () => onReuse(entry),
                          onDelete: () => onDelete(entry),
                          onCopyResult: onCopyResult,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onReuse,
    required this.onDelete,
    this.onCopyResult,
  });

  final CalcHistoryEntry entry;
  final VoidCallback onReuse;
  final VoidCallback onDelete;
  final ValueChanged<String>? onCopyResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key('history_${entry.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(l10n.deleteHistoryItem, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
      ),
      child: Semantics(
        button: true,
        label: l10n.semanticsHistoryEntry(entry.expression, entry.result),
        hint: l10n.tapToCopyHistory,
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onReuse,
            onLongPress: onCopyResult != null
                ? () => onCopyResult!(entry.result)
                : null,
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.expression,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '= ${entry.result}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
