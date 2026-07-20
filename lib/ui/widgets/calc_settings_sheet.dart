import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import 'calc_dialog_header.dart';
import 'keyboard_shortcuts_section.dart';

/// Minimum comfortable width for settings on tablet/desktop.
const _settingsMinWidth = 480.0;
const _settingsMaxWidth = 560.0;

Future<void> showCalcSettingsSheet(BuildContext context, AppSettings settings) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _SettingsDialog(settings: settings),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxWidth: width >= 480 ? _settingsMaxWidth : width,
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 28,
            ),
            child: CalcSettingsContent(settings: settings),
          ),
        );
      },
    ),
  );
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _settingsMaxWidth,
          minWidth: size.width >= _settingsMinWidth
              ? _settingsMinWidth
              : size.width * 0.92,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: CalcDialogHeader(
                title: AppLocalizations.of(context)!.settings,
                icon: Icons.settings_outlined,
                onClose: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: CalcSettingsContent(settings: settings, hideTitle: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalcSettingsContent extends StatelessWidget {
  const CalcSettingsContent({
    super.key,
    required this.settings,
    this.hideTitle = false,
  });

  final AppSettings settings;
  final bool hideTitle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hideTitle) ...[
              Text(l10n.settings, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
            ],
            Text(l10n.theme, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
            const SizedBox(height: 20),
            Text(l10n.language, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ButtonSegment(value: 'fa', label: Text(l10n.languagePersian)),
              ],
              selected: {settings.locale?.languageCode ?? 'en'},
              onSelectionChanged: (s) {
                settings.setLocale(Locale(s.first));
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.haptics),
              value: settings.hapticsEnabled,
              onChanged: settings.setHapticsEnabled,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.persistHistory),
              value: settings.persistHistory,
              onChanged: settings.setPersistHistory,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.restoreSession),
              subtitle: Text(
                l10n.restoreSessionHint,
                style: theme.textTheme.bodySmall,
              ),
              value: settings.restoreSession,
              onChanged: settings.setRestoreSession,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.persianDigits),
              value: settings.usePersianDigits,
              onChanged: settings.setPersianDigits,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.touchLock),
              value: settings.touchLock,
              onChanged: settings.setTouchLock,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.showRunningTotal),
              subtitle: Text(
                l10n.showRunningTotalHint,
                style: theme.textTheme.bodySmall,
              ),
              value: settings.showRunningTotal,
              onChanged: settings.setShowRunningTotal,
            ),
            const Divider(height: 32),
            Text(l10n.aboutCalc, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              l10n.aboutChainedCalc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.clearEntryHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 32),
            const KeyboardShortcutsSection(),
            const SizedBox(height: 16),
            Text(
              l10n.privacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}
