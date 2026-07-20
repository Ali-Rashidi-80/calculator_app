import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get appTitle;

  /// No description provided for @errorDivisionByZero.
  ///
  /// In en, this message translates to:
  /// **'Cannot divide by zero'**
  String get errorDivisionByZero;

  /// No description provided for @errorOverflow.
  ///
  /// In en, this message translates to:
  /// **'Number too large'**
  String get errorOverflow;

  /// No description provided for @errorInvalidPaste.
  ///
  /// In en, this message translates to:
  /// **'Invalid number to paste'**
  String get errorInvalidPaste;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed — check clipboard permissions'**
  String get copyFailed;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get cleared;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No calculations yet'**
  String get historyEmpty;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @deleteHistoryItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteHistoryItem;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePersian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get languagePersian;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Button haptics'**
  String get haptics;

  /// No description provided for @persistHistory.
  ///
  /// In en, this message translates to:
  /// **'Keep history after close'**
  String get persistHistory;

  /// No description provided for @restoreSession.
  ///
  /// In en, this message translates to:
  /// **'Restore last session on open'**
  String get restoreSession;

  /// No description provided for @persianDigits.
  ///
  /// In en, this message translates to:
  /// **'Show Persian digits (۰–۹)'**
  String get persianDigits;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'All data stays on your device. No ads. No cloud.'**
  String get privacyNote;

  /// No description provided for @swipeHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe down for history · Swipe left on display to delete a digit'**
  String get swipeHistoryHint;

  /// No description provided for @aboutCalc.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutCalc;

  /// No description provided for @aboutChainedCalc.
  ///
  /// In en, this message translates to:
  /// **'Operations run left-to-right (not PEMDAS). Example: 2 + 3 × 4 = 20. Press = again to repeat the last operation.'**
  String get aboutChainedCalc;

  /// No description provided for @keyboardHint.
  ///
  /// In en, this message translates to:
  /// **'See Settings → Keyboard shortcuts for the full list'**
  String get keyboardHint;

  /// No description provided for @keyboardShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcutsTitle;

  /// No description provided for @keyboardShortcutsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcutsTooltip;

  /// No description provided for @keyboardShortcutNav.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get keyboardShortcutNav;

  /// No description provided for @keyboardShortcutNavKeys.
  ///
  /// In en, this message translates to:
  /// **'Arrow keys move focus · Home / End · Space = activate focused key · Enter = equals · Esc = clear all'**
  String get keyboardShortcutNavKeys;

  /// No description provided for @keyboardShortcutEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get keyboardShortcutEdit;

  /// No description provided for @keyboardShortcutEditKeys.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Z undo · Ctrl+Y redo · Ctrl+V paste · Shift+Insert paste · Backspace · Delete = clear entry'**
  String get keyboardShortcutEditKeys;

  /// No description provided for @keyboardShortcutMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get keyboardShortcutMemory;

  /// No description provided for @keyboardShortcutMemoryKeys.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+M store · Ctrl+P add · Ctrl+Q subtract · Ctrl+R recall · Ctrl+L clear'**
  String get keyboardShortcutMemoryKeys;

  /// No description provided for @keyboardShortcutHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get keyboardShortcutHistory;

  /// No description provided for @keyboardShortcutHistoryKeys.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+H open panel · Ctrl+Shift+H export · Ctrl+Shift+D clear all'**
  String get keyboardShortcutHistoryKeys;

  /// No description provided for @keyboardShortcutCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy & paste'**
  String get keyboardShortcutCopy;

  /// No description provided for @keyboardShortcutCopyKeys.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Shift+C copy expression · Long-press display for copy/paste menu'**
  String get keyboardShortcutCopyKeys;

  /// No description provided for @keyboardShortcutSign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get keyboardShortcutSign;

  /// No description provided for @keyboardShortcutSignKeys.
  ///
  /// In en, this message translates to:
  /// **'F9 or Shift+− toggle sign'**
  String get keyboardShortcutSignKeys;

  /// No description provided for @semanticsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get semanticsClear;

  /// No description provided for @semanticsToggleSign.
  ///
  /// In en, this message translates to:
  /// **'Toggle sign'**
  String get semanticsToggleSign;

  /// No description provided for @semanticsPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get semanticsPercent;

  /// No description provided for @semanticsDivide.
  ///
  /// In en, this message translates to:
  /// **'Divide'**
  String get semanticsDivide;

  /// No description provided for @semanticsMultiply.
  ///
  /// In en, this message translates to:
  /// **'Multiply'**
  String get semanticsMultiply;

  /// No description provided for @semanticsSubtract.
  ///
  /// In en, this message translates to:
  /// **'Subtract'**
  String get semanticsSubtract;

  /// No description provided for @semanticsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get semanticsAdd;

  /// No description provided for @semanticsDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal point'**
  String get semanticsDecimal;

  /// No description provided for @semanticsEquals.
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get semanticsEquals;

  /// No description provided for @semanticsBackspace.
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get semanticsBackspace;

  /// No description provided for @semanticsDisplayResult.
  ///
  /// In en, this message translates to:
  /// **'Result: {value}'**
  String semanticsDisplayResult(String value);

  /// No description provided for @semanticsDisplayError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String semanticsDisplayError(String message);

  /// No description provided for @semanticsMemoryActive.
  ///
  /// In en, this message translates to:
  /// **'Memory has a stored value'**
  String get semanticsMemoryActive;

  /// No description provided for @semanticsHistoryEntry.
  ///
  /// In en, this message translates to:
  /// **'{expression}, equals {result}'**
  String semanticsHistoryEntry(String expression, String result);

  /// No description provided for @noExpressionToCopy.
  ///
  /// In en, this message translates to:
  /// **'No expression to copy'**
  String get noExpressionToCopy;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @pasteTrimmed.
  ///
  /// In en, this message translates to:
  /// **'Pasted number was trimmed to fit display'**
  String get pasteTrimmed;

  /// No description provided for @nothingToUndo.
  ///
  /// In en, this message translates to:
  /// **'Nothing to undo'**
  String get nothingToUndo;

  /// No description provided for @nothingToRedo.
  ///
  /// In en, this message translates to:
  /// **'Nothing to redo'**
  String get nothingToRedo;

  /// No description provided for @memoryStored.
  ///
  /// In en, this message translates to:
  /// **'Value stored in memory'**
  String get memoryStored;

  /// No description provided for @memoryRecalled.
  ///
  /// In en, this message translates to:
  /// **'Value recalled from memory'**
  String get memoryRecalled;

  /// No description provided for @memoryClearedAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Memory cleared'**
  String get memoryClearedAnnounce;

  /// No description provided for @restoreSessionHint.
  ///
  /// In en, this message translates to:
  /// **'Restore display and pending operation when reopening'**
  String get restoreSessionHint;

  /// No description provided for @nothingInMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory is empty'**
  String get nothingInMemory;

  /// No description provided for @noEqualsPending.
  ///
  /// In en, this message translates to:
  /// **'No calculation to complete'**
  String get noEqualsPending;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @pasteAction.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteAction;

  /// No description provided for @memoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to memory'**
  String get memoryAdded;

  /// No description provided for @memorySubtracted.
  ///
  /// In en, this message translates to:
  /// **'Subtracted from memory'**
  String get memorySubtracted;

  /// No description provided for @touchLock.
  ///
  /// In en, this message translates to:
  /// **'Lock touch input (keyboard still works)'**
  String get touchLock;

  /// No description provided for @touchLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Touch locked — use keyboard or turn off in Settings'**
  String get touchLockedHint;

  /// No description provided for @tapToCopyHistory.
  ///
  /// In en, this message translates to:
  /// **'Tap to reuse result · Long-press or double-tap display to copy'**
  String get tapToCopyHistory;

  /// No description provided for @tapToCopyDisplay.
  ///
  /// In en, this message translates to:
  /// **'Long-press display for copy/paste · double-tap to copy'**
  String get tapToCopyDisplay;

  /// No description provided for @memoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Memory add (M+)'**
  String get memoryAdd;

  /// No description provided for @memorySubtract.
  ///
  /// In en, this message translates to:
  /// **'Memory subtract (M−)'**
  String get memorySubtract;

  /// No description provided for @memoryRecall.
  ///
  /// In en, this message translates to:
  /// **'Memory recall (MR)'**
  String get memoryRecall;

  /// No description provided for @memoryClear.
  ///
  /// In en, this message translates to:
  /// **'Memory clear (MC)'**
  String get memoryClear;

  /// No description provided for @memoryIndicator.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get memoryIndicator;

  /// No description provided for @clearEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press C or Delete key to clear entry only (CE)'**
  String get clearEntryHint;

  /// No description provided for @showRunningTotal.
  ///
  /// In en, this message translates to:
  /// **'Running total preview'**
  String get showRunningTotal;

  /// No description provided for @showRunningTotalHint.
  ///
  /// In en, this message translates to:
  /// **'Live subtotal while typing (iOS 17 style — useful for shopping totals)'**
  String get showRunningTotalHint;

  /// No description provided for @exportHistory.
  ///
  /// In en, this message translates to:
  /// **'Export history to clipboard'**
  String get exportHistory;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// No description provided for @historyItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'History item deleted'**
  String get historyItemDeleted;

  /// No description provided for @runningTotalPreview.
  ///
  /// In en, this message translates to:
  /// **'Running total: {total}'**
  String runningTotalPreview(String total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
