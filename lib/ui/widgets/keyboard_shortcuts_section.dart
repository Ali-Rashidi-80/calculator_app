import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../calc_rtl.dart';
import 'calc_dialog_header.dart';

/// Grouped keyboard shortcuts — cards + chips for desktop and settings.
class KeyboardShortcutsSection extends StatelessWidget {
  const KeyboardShortcutsSection({
    super.key,
    this.dense = false,
    this.hideTitle = false,
    this.twoColumn = false,
  });

  final bool dense;
  final bool hideTitle;
  final bool twoColumn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRtl = calcIsRtl(context);
    final gap = dense ? 10.0 : 14.0;

    final groups = _groups(l10n);

    final cards = groups
        .map(
          (g) => _ShortcutGroupCard(
            icon: g.icon,
            title: g.title,
            keys: g.keys,
            compact: dense,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hideTitle) ...[
          Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Icon(
                Icons.keyboard_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.keyboardShortcutsTitle,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
        ],
        if (twoColumn && cards.length > 3)
          ..._pairRows(cards, gap)
        else
          ...cards.expand((c) => [c, SizedBox(height: gap)]).toList()
            ..removeLast(),
      ],
    );
  }

  List<Widget> _pairRows(List<Widget> cards, double gap) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: gap));
      if (i + 1 < cards.length) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 12),
                Expanded(child: cards[i + 1]),
              ],
            ),
          ),
        );
      } else {
        rows.add(cards[i]);
      }
    }
    return rows;
  }

  static List<({IconData icon, String title, String keys})> _groups(
    AppLocalizations l10n,
  ) => [
    (
      icon: Icons.ads_click_outlined,
      title: l10n.keyboardShortcutNav,
      keys: l10n.keyboardShortcutNavKeys,
    ),
    (
      icon: Icons.edit_note_outlined,
      title: l10n.keyboardShortcutEdit,
      keys: l10n.keyboardShortcutEditKeys,
    ),
    (
      icon: Icons.save_outlined,
      title: l10n.keyboardShortcutMemory,
      keys: l10n.keyboardShortcutMemoryKeys,
    ),
    (
      icon: Icons.history,
      title: l10n.keyboardShortcutHistory,
      keys: l10n.keyboardShortcutHistoryKeys,
    ),
    (
      icon: Icons.content_copy_outlined,
      title: l10n.keyboardShortcutCopy,
      keys: l10n.keyboardShortcutCopyKeys,
    ),
    (
      icon: Icons.exposure_neg_1_outlined,
      title: l10n.keyboardShortcutSign,
      keys: l10n.keyboardShortcutSignKeys,
    ),
  ];
}

class _ShortcutGroupCard extends StatelessWidget {
  const _ShortcutGroupCard({
    required this.icon,
    required this.title,
    required this.keys,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String keys;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = calcIsRtl(context);
    final items = keys.split(' · ').where((s) => s.trim().isNotEmpty).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 14,
          compact ? 10 : 12,
          compact ? 12 : 14,
          compact ? 12 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: isRtl ? WrapAlignment.end : WrapAlignment.start,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: items
                  .map((item) => _ShortcutChip(label: item))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.25,
        ),
      ),
    );
  }
}

Future<void> showKeyboardShortcutsDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final size = MediaQuery.sizeOf(context);
  final theme = Theme.of(context);
  final twoCol = size.width >= 560;

  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: twoCol ? 640 : 520,
          minWidth: size.width >= 480 ? 480 : size.width * 0.92,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: CalcDialogHeader(
                  title: l10n.keyboardShortcutsTitle,
                  icon: Icons.keyboard_outlined,
                  onClose: () => Navigator.pop(ctx),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: KeyboardShortcutsSection(
                  dense: true,
                  hideTitle: true,
                  twoColumn: twoCol,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
