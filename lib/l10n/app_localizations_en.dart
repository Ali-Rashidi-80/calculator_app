// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calculator';

  @override
  String get errorDivisionByZero => 'Cannot divide by zero';

  @override
  String get errorOverflow => 'Number too large';

  @override
  String get errorInvalidPaste => 'Invalid number to paste';

  @override
  String get copied => 'Copied';

  @override
  String get copyFailed => 'Copy failed — check clipboard permissions';

  @override
  String get cleared => 'Cleared';

  @override
  String get history => 'History';

  @override
  String get historyEmpty => 'No calculations yet';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get deleteHistoryItem => 'Delete';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'Persian';

  @override
  String get haptics => 'Button haptics';

  @override
  String get persistHistory => 'Keep history after close';

  @override
  String get restoreSession => 'Restore last session on open';

  @override
  String get persianDigits => 'Show Persian digits (۰–۹)';

  @override
  String get privacyNote => 'All data stays on your device. No ads. No cloud.';

  @override
  String get swipeHistoryHint =>
      'Swipe down for history · Swipe left on display to delete a digit';

  @override
  String get aboutCalc => 'About';

  @override
  String get aboutChainedCalc =>
      'Operations run left-to-right (not PEMDAS). Example: 2 + 3 × 4 = 20. Press = again to repeat the last operation.';

  @override
  String get keyboardHint =>
      'See Settings → Keyboard shortcuts for the full list';

  @override
  String get keyboardShortcutsTitle => 'Keyboard shortcuts';

  @override
  String get keyboardShortcutsTooltip => 'Keyboard shortcuts';

  @override
  String get keyboardShortcutNav => 'Navigate';

  @override
  String get keyboardShortcutNavKeys =>
      'Arrow keys move focus · Home / End · Space or Enter = equals · Esc = clear all';

  @override
  String get keyboardShortcutEdit => 'Edit';

  @override
  String get keyboardShortcutEditKeys =>
      'Ctrl+Z undo · Ctrl+Y redo · Ctrl+V paste · Shift+Insert paste · Backspace · Delete = clear entry';

  @override
  String get keyboardShortcutMemory => 'Memory';

  @override
  String get keyboardShortcutMemoryKeys =>
      'Ctrl+M store · Ctrl+P add · Ctrl+Q subtract · Ctrl+R recall · Ctrl+L clear';

  @override
  String get keyboardShortcutHistory => 'History';

  @override
  String get keyboardShortcutHistoryKeys =>
      'Ctrl+H open panel · Ctrl+Shift+H export · Ctrl+Shift+D clear all';

  @override
  String get keyboardShortcutCopy => 'Copy & paste';

  @override
  String get keyboardShortcutCopyKeys =>
      'Ctrl+Shift+C copy expression · Long-press display for copy/paste menu';

  @override
  String get keyboardShortcutSign => 'Sign';

  @override
  String get keyboardShortcutSignKeys => 'F9 or Shift+− toggle sign';

  @override
  String get semanticsClear => 'Clear all';

  @override
  String get semanticsToggleSign => 'Toggle sign';

  @override
  String get semanticsPercent => 'Percent';

  @override
  String get semanticsDivide => 'Divide';

  @override
  String get semanticsMultiply => 'Multiply';

  @override
  String get semanticsSubtract => 'Subtract';

  @override
  String get semanticsAdd => 'Add';

  @override
  String get semanticsDecimal => 'Decimal point';

  @override
  String get semanticsEquals => 'Equals';

  @override
  String get semanticsBackspace => 'Backspace';

  @override
  String semanticsDisplayResult(String value) {
    return 'Result: $value';
  }

  @override
  String semanticsDisplayError(String message) {
    return 'Error: $message';
  }

  @override
  String get semanticsMemoryActive => 'Memory has a stored value';

  @override
  String semanticsHistoryEntry(String expression, String result) {
    return '$expression, equals $result';
  }

  @override
  String get noExpressionToCopy => 'No expression to copy';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String get pasteTrimmed => 'Pasted number was trimmed to fit display';

  @override
  String get nothingToUndo => 'Nothing to undo';

  @override
  String get nothingToRedo => 'Nothing to redo';

  @override
  String get memoryStored => 'Value stored in memory';

  @override
  String get memoryRecalled => 'Value recalled from memory';

  @override
  String get memoryClearedAnnounce => 'Memory cleared';

  @override
  String get restoreSessionHint =>
      'Restore display and pending operation when reopening';

  @override
  String get nothingInMemory => 'Memory is empty';

  @override
  String get noEqualsPending => 'No calculation to complete';

  @override
  String get copyAction => 'Copy';

  @override
  String get pasteAction => 'Paste';

  @override
  String get memoryAdded => 'Added to memory';

  @override
  String get memorySubtracted => 'Subtracted from memory';

  @override
  String get touchLock => 'Lock touch input (keyboard still works)';

  @override
  String get touchLockedHint =>
      'Touch locked — use keyboard or turn off in Settings';

  @override
  String get tapToCopyHistory =>
      'Tap to reuse result · Long-press or double-tap display to copy';

  @override
  String get tapToCopyDisplay =>
      'Long-press display for copy/paste · double-tap to copy';

  @override
  String get memoryAdd => 'Memory add (M+)';

  @override
  String get memorySubtract => 'Memory subtract (M−)';

  @override
  String get memoryRecall => 'Memory recall (MR)';

  @override
  String get memoryClear => 'Memory clear (MC)';

  @override
  String get memoryIndicator => 'M';

  @override
  String get clearEntryHint =>
      'Long-press C or Delete key to clear entry only (CE)';

  @override
  String get showRunningTotal => 'Running total preview';

  @override
  String get showRunningTotalHint =>
      'Live subtotal while typing (iOS 17 style — useful for shopping totals)';

  @override
  String get exportHistory => 'Export history to clipboard';

  @override
  String get historyCleared => 'History cleared';

  @override
  String get historyItemDeleted => 'History item deleted';

  @override
  String runningTotalPreview(String total) {
    return 'Running total: $total';
  }
}
