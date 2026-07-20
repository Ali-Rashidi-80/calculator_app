import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../calculator.dart';
import '../utils/digit_locale.dart';
import '../models/calc_history_entry.dart';
import '../l10n/app_localizations.dart';
import '../services/calc_persistence.dart';
import '../settings/app_settings.dart';
import '../theme/app_theme.dart';
import 'calc_layout.dart';
import 'calc_rtl.dart';
import 'calc_keypad_grid.dart';
import 'widgets/calc_display_panel.dart';
import 'widgets/calc_history_panel.dart';
import 'widgets/calc_keypad.dart';
import 'widgets/calc_memory_bar.dart';
import 'widgets/calc_settings_sheet.dart';
import 'widgets/keyboard_shortcuts_section.dart';
import 'widgets/keypad_semantics.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with WidgetsBindingObserver {
  final Calculator _calc = Calculator();
  final FocusNode _focusNode = FocusNode();
  CalcPersistence? _persistence;
  String? _error;
  bool _loaded = false;
  String? _keypadFocusId;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPersistence();
  }

  Future<void> _initPersistence() async {
    final p = await CalcPersistence.load();
    if (!mounted) return;
    _persistence = p;
    if (widget.settings.restoreSession) {
      final session = p.readSession();
      final memory = p.readMemory();
      if (session != null) {
        _calc.restoreSession(session, memory: memory);
      } else if (memory != null) {
        _calc.restoreSession(
          const CalculatorSession(display: '0'),
          memory: memory,
        );
      }
    } else {
      // Memory persists even when session restore is off (MS #2315 / manufacturing).
      final memory = p.readMemory();
      if (memory != null) {
        _calc.restoreSession(
          const CalculatorSession(display: '0'),
          memory: memory,
        );
      }
    }
    if (widget.settings.persistHistory) {
      _calc.loadHistory(p.readHistory());
    }
    setState(() => _loaded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusKeyboard());
  }

  void _refocusKeyboard() {
    if (mounted && _focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persist();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persist();
    }
    if (state == AppLifecycleState.resumed) {
      _refocusKeyboard();
    }
  }

  Future<void> _persist() async {
    final p = _persistence;
    if (p == null || !_loaded) return;
    // Snapshot before awaits — dispose may have run (H7).
    final persistHistory = widget.settings.persistHistory;
    final session = _calc.exportSession();
    final memory = _calc.memoryValue;
    final history = List.of(_calc.history.entries);
    await p.writeSession(session);
    await p.writeMemory(memory);
    if (persistHistory) {
      await p.writeHistory(history);
    } else {
      await p.writeHistory([]);
    }
  }

  void _refresh({String? error, bool clearError = false}) {
    setState(() {
      if (clearError) {
        _error = null;
      } else if (error != null) {
        _error = error;
      }
    });
  }

  void _onDigit(String d) {
    _calc.inputDigit(DigitLocale.normalizeToAscii(d));
    _refresh(clearError: true);
  }

  void _onClear({bool announce = false}) {
    _calc.clear();
    _refresh(clearError: true);
    _persist();
    if (announce && mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        _l10n.cleared,
        Directionality.of(context),
      );
    }
  }

  void _onClearEntry() {
    _calc.clearEntry();
    _refresh(clearError: true);
    _persist();
  }

  void _announce(String message) {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  void _showBriefHint(String message) {
    if (!mounted) return;
    _announce(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _onMemoryStore() {
    _calc.memoryStore();
    setState(() {});
    _persist();
    _announce(_l10n.memoryStored);
  }

  void _onMemoryAdd() {
    _calc.memoryAdd();
    setState(() {});
    _persist();
    _announce(_l10n.memoryAdded);
  }

  void _onMemorySubtract() {
    _calc.memorySubtract();
    setState(() {});
    _persist();
    _announce(_l10n.memorySubtracted);
  }

  void _onMemoryRecall() {
    if (!_calc.canMemoryRecall) {
      _showBriefHint(_l10n.nothingInMemory);
      return;
    }
    try {
      _calc.memoryRecall();
      _refresh(clearError: true);
      _persist();
      _announce(_l10n.memoryRecalled);
    } on CalculatorError catch (e) {
      _handleCalcError(e);
    }
  }

  void _onMemoryClear() {
    if (!_calc.canMemoryClear) {
      _showBriefHint(_l10n.nothingInMemory);
      return;
    }
    _calc.memoryClear();
    setState(() {});
    _persist();
    _announce(_l10n.memoryClearedAnnounce);
  }

  void _handleCalcError(CalculatorError e) {
    final message = switch (e) {
      CalculatorError.divisionByZero => _l10n.errorDivisionByZero,
      CalculatorError.overflow => _l10n.errorOverflow,
    };
    _refresh(error: message);
    _calc.clear();
    _persist();
    if (mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    }
  }

  void _onOp(String op) {
    try {
      _calc.setOperation(op);
      _refresh(clearError: true);
    } on CalculatorError catch (e) {
      _handleCalcError(e);
    }
  }

  void _onEquals() {
    try {
      _calc.equals();
      _refresh(clearError: true);
      _persist();
      if (mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          _calc.display,
          Directionality.of(context),
        );
      }
    } on CalculatorError catch (e) {
      _handleCalcError(e);
    }
  }

  void _onUndo() {
    if (!_calc.canUndo) {
      _showBriefHint(_l10n.nothingToUndo);
      return;
    }
    _calc.undo();
    _refresh(clearError: true);
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusKeyboard());
  }

  void _onRedo() {
    if (!_calc.canRedo) {
      _showBriefHint(_l10n.nothingToRedo);
      return;
    }
    _calc.redo();
    _refresh(clearError: true);
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusKeyboard());
  }

  void _copyResult() {
    _copyText(_error ?? _calc.copyPlainText);
  }

  Future<void> _copyText(String text) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_l10n.copied),
        duration: const Duration(seconds: 1),
      ),
    );
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.copyFailed),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _exportHistory() {
    if (_calc.history.isEmpty) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        _l10n.historyEmpty,
        Directionality.of(context),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.historyEmpty),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _copyText(_calc.exportHistoryText());
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        _l10n.clipboardEmpty,
        Directionality.of(context),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.clipboardEmpty),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      if (!_calc.pasteFromText(text)) {
        _refresh(error: _l10n.errorInvalidPaste);
        if (mounted) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            _l10n.errorInvalidPaste,
            Directionality.of(context),
          );
        }
        return;
      }
      _refresh(clearError: true);
      _persist();
      if (_calc.lastPasteTrimmed && mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          _l10n.pasteTrimmed,
          Directionality.of(context),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.pasteTrimmed),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on CalculatorError catch (e) {
      _handleCalcError(e);
    }
  }

  void _onBackspace() {
    if (!_calc.canBackspace) return;
    _calc.deleteLast();
    _refresh(clearError: true);
  }

  void _onReuseHistory(CalcHistoryEntry entry, {VoidCallback? closeSheet}) {
    _calc.loadResult(entry.result);
    closeSheet?.call();
    _refresh(clearError: true);
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusKeyboard());
  }

  void _onDeleteHistory(CalcHistoryEntry entry) {
    _calc.deleteHistoryEntry(entry.id);
    setState(() {});
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusKeyboard());
    if (mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        _l10n.historyItemDeleted,
        Directionality.of(context),
      );
    }
  }

  void _clearHistory({bool announce = false}) {
    _calc.clearHistory();
    setState(() {});
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusKeyboard());
    if (announce && mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        _l10n.historyCleared,
        Directionality.of(context),
      );
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final height = MediaQuery.sizeOf(ctx).height * 0.55;
        return SizedBox(
          height: height,
          child: CalcHistoryPanel(
            entries: _calc.history.entries,
            onClear: () {
              _clearHistory(announce: true);
              Navigator.pop(ctx);
            },
            onReuse: (e) =>
                _onReuseHistory(e, closeSheet: () => Navigator.pop(ctx)),
            onDelete: _onDeleteHistory,
            onExport: _exportHistory,
            onCopyResult: _copyText,
            compact: true,
          ),
        );
      },
    ).then((_) {
      setState(() {});
      _refocusKeyboard();
    });
  }

  void _ensureKeypadFocus() {
    _keypadFocusId ??= CalcKeypadGrid.homeKey;
  }

  void _moveKeypadFocus({required int dRow, required int dCol}) {
    _ensureKeypadFocus();
    var current = _keypadFocusId!;
    for (var step = 0; step < 24; step++) {
      final next = CalcKeypadGrid.move(current, dRow: dRow, dCol: dCol);
      if (next == current) break;
      current = next;
      if (_isKeypadKeyEnabled(current)) {
        setState(() => _keypadFocusId = current);
        return;
      }
    }
  }

  bool _isKeypadKeyEnabled(String id) {
    switch (id) {
      case 'eq':
        return _calc.canEquals;
      case 'sign':
        return _calc.canToggleSign;
      case 'dot':
        return _calc.canInputDecimal;
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        return _calc.canInputDigit;
      default:
        return true;
    }
  }

  void _activateKeypadFocus() {
    _ensureKeypadFocus();
    switch (_keypadFocusId) {
      case 'clear':
        _onClear();
      case 'sign':
        if (_calc.canToggleSign) {
          _calc.toggleSign();
          _refresh(clearError: true);
        }
      case 'pct':
        try {
          _calc.percent();
          _refresh(clearError: true);
        } on CalculatorError catch (e) {
          _handleCalcError(e);
        }
      case 'div':
        _onOp('÷');
      case '7':
      case '8':
      case '9':
        if (_calc.canInputDigit) _onDigit(_keypadFocusId!);
      case 'mul':
        _onOp('×');
      case '4':
      case '5':
      case '6':
        if (_calc.canInputDigit) _onDigit(_keypadFocusId!);
      case 'sub':
        _onOp('-');
      case '1':
      case '2':
      case '3':
        if (_calc.canInputDigit) _onDigit(_keypadFocusId!);
      case 'add':
        _onOp('+');
      case '0':
        if (_calc.canInputDigit) _onDigit('0');
      case 'dot':
        if (_calc.canInputDecimal) {
          _calc.inputDecimal();
          _refresh(clearError: true);
        }
      case 'eq':
        if (_calc.canEquals) _onEquals();
      default:
        break;
    }
  }

  void _showTouchLockedHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_l10n.touchLockedHint),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final label = key.keyLabel;
    final ctrl = HardwareKeyboard.instance.isControlPressed;

    if (ctrl && key == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _onRedo();
      } else {
        _onUndo();
      }
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyY) {
      _onRedo();
      return KeyEventResult.handled;
    }

    if (ctrl && key == LogicalKeyboardKey.keyC) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        final expr = _calc.expression;
        if (expr.isNotEmpty) {
          _copyText(expr);
        } else if (mounted) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            _l10n.noExpressionToCopy,
            Directionality.of(context),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n.noExpressionToCopy),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        _copyResult();
      }
      return KeyEventResult.handled;
    }

    if (ctrl && key == LogicalKeyboardKey.keyV) {
      _pasteFromClipboard();
      return KeyEventResult.handled;
    }
    if (HardwareKeyboard.instance.isShiftPressed &&
        key == LogicalKeyboardKey.insert) {
      _pasteFromClipboard();
      return KeyEventResult.handled;
    }

    if (ctrl && key == LogicalKeyboardKey.keyM) {
      _onMemoryStore();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyP) {
      _onMemoryAdd();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyQ) {
      _onMemorySubtract();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyR) {
      _onMemoryRecall();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyL) {
      _onMemoryClear();
      return KeyEventResult.handled;
    }
    if (ctrl &&
        HardwareKeyboard.instance.isShiftPressed &&
        key == LogicalKeyboardKey.keyD) {
      if (!_calc.history.isEmpty) {
        _clearHistory(announce: true);
      }
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyH) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _exportHistory();
      } else if (!CalcLayout.of(context).showSideHistory) {
        _showHistorySheet();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _moveKeypadFocus(dRow: -1, dCol: 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveKeypadFocus(dRow: 1, dCol: 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveKeypadFocus(dRow: 0, dCol: -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveKeypadFocus(dRow: 0, dCol: 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      setState(() => _keypadFocusId = CalcKeypadGrid.homeKey);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      setState(
        () => _keypadFocusId = _calc.canEquals ? CalcKeypadGrid.endKey : 'add',
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _activateKeypadFocus();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        label == '=') {
      if (_calc.canEquals) {
        _onEquals();
      } else {
        _showBriefHint(_l10n.noEqualsPending);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape ||
        (!ctrl && label.toLowerCase() == 'c')) {
      _onClear(announce: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      if (_calc.canBackspace) _onBackspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _onClearEntry();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f9) {
      if (_calc.canToggleSign) {
        _calc.toggleSign();
        _refresh(clearError: true);
      }
      return KeyEventResult.handled;
    }
    if (HardwareKeyboard.instance.isShiftPressed &&
        (key == LogicalKeyboardKey.minus || label == '_')) {
      if (_calc.canToggleSign) {
        _calc.toggleSign();
        _refresh(clearError: true);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadAdd) {
      _onOp('+');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadSubtract) {
      _onOp('-');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadMultiply) {
      _onOp('×');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadDivide) {
      _onOp('÷');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadDecimal) {
      if (_calc.canInputDecimal) {
        _calc.inputDecimal();
        _refresh(clearError: true);
      }
      return KeyEventResult.handled;
    }
    final numpadDigits = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };
    if (numpadDigits.containsKey(key)) {
      if (_calc.canInputDigit) _onDigit(numpadDigits[key]!);
      return KeyEventResult.handled;
    }
    if (label == '.' || label == ',' || label == '٫' || label == '،') {
      if (_calc.canInputDecimal) {
        _calc.inputDecimal();
        _refresh(clearError: true);
      }
      return KeyEventResult.handled;
    }
    if (label == '%') {
      _calc.percent();
      _refresh(clearError: true);
      return KeyEventResult.handled;
    }
    final digit = DigitLocale.normalizeToAscii(label);
    if (digit.length == 1 && '0123456789'.contains(digit)) {
      if (_calc.canInputDigit) _onDigit(digit);
      return KeyEventResult.handled;
    }

    const opMap = {'+': '+', '-': '-', '*': '×', '/': '÷'};
    if (opMap.containsKey(label)) {
      _onOp(opMap[label]!);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final calcTheme = CalcTheme.of(context);
    final l10n = _l10n;
    final layout = CalcLayout.of(context);
    final haptics = widget.settings.hapticsEnabled;
    final touchEnabled = widget.settings.touchInputEnabled;

    final calcCard = _CalculatorCard(
      calc: _calc,
      error: _error,
      showRunningTotal: widget.settings.showRunningTotal,
      enableHaptics: haptics,
      touchEnabled: touchEnabled,
      onTouchBlocked: _showTouchLockedHint,
      keypadFocusId: _keypadFocusId,
      usePersianDigits: widget.settings.usePersianDigits,
      onCopy: _copyResult,
      onPaste: _pasteFromClipboard,
      onClear: () => _onClear(),
      onClearEntry: () {
        _onClearEntry();
      },
      onSwipeDown: layout.showSideHistory ? null : _showHistorySheet,
      onSign: () {
        _calc.toggleSign();
        _refresh(clearError: true);
      },
      onPercent: () {
        try {
          _calc.percent();
          _refresh(clearError: true);
        } on CalculatorError catch (e) {
          _handleCalcError(e);
        }
      },
      onDivide: () => _onOp('÷'),
      onDigit: _onDigit,
      onMultiply: () => _onOp('×'),
      onSubtract: () => _onOp('-'),
      onAdd: () => _onOp('+'),
      onDecimal: () {
        _calc.inputDecimal();
        _refresh(clearError: true);
      },
      onEquals: _onEquals,
      onBackspace: _onBackspace,
      onMemoryAdd: _onMemoryAdd,
      onMemorySubtract: _onMemorySubtract,
      onMemoryRecall: _onMemoryRecall,
      onMemoryClear: _onMemoryClear,
    );

    final toolbarIcons = <Widget>[
      if (!layout.showSideHistory)
        Semantics(
          button: true,
          label: l10n.history,
          child: IconButton(
            key: const Key('btn_history'),
            tooltip: l10n.history,
            onPressed: _showHistorySheet,
            icon: Badge(
              isLabelVisible: _calc.history.entries.isNotEmpty,
              label: Text('${_calc.history.entries.length}'),
              child: const Icon(Icons.history),
            ),
          ),
        ),
      Semantics(
        button: true,
        label: l10n.settings,
        child: IconButton(
          key: const Key('btn_settings'),
          tooltip: l10n.settings,
          onPressed: () {
            showCalcSettingsSheet(context, widget.settings).then((_) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _refocusKeyboard(),
              );
            });
          },
          icon: Icon(
            widget.settings.touchLock
                ? Icons.lock_outline
                : Icons.settings_outlined,
          ),
        ),
      ),
      if (layout.showKeyboardShortcutsButton)
        Semantics(
          button: true,
          label: l10n.keyboardShortcutsTitle,
          child: IconButton(
            key: const Key('btn_keyboard_shortcuts'),
            tooltip: l10n.keyboardShortcutsTooltip,
            onPressed: () => showKeyboardShortcutsDialog(context),
            icon: const Icon(Icons.keyboard_outlined),
          ),
        ),
    ];

    final isRtl = calcIsRtl(context);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(l10n.appTitle),
          leading: isRtl
              ? Row(mainAxisSize: MainAxisSize.min, children: toolbarIcons)
              : null,
          leadingWidth: isRtl ? toolbarIcons.length * 48.0 : null,
          actions: isRtl ? null : toolbarIcons,
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: calcTheme.backdropGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: layout.pagePadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: layout.maxContentWidth,
                    maxHeight: layout.maxContentHeight,
                  ),
                  child: layout.showSideHistory
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          textDirection: TextDirection.ltr,
                          children: [
                            Expanded(
                              flex: 11,
                              child: CalcHistoryPanel(
                                entries: _calc.history.entries,
                                onClear: () => _clearHistory(announce: true),
                                onReuse: (e) => _onReuseHistory(e),
                                onDelete: _onDeleteHistory,
                                onExport: _exportHistory,
                                onCopyResult: _copyText,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 13, child: calcCard),
                          ],
                        )
                      : calcCard,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  const _CalculatorCard({
    required this.calc,
    required this.error,
    required this.showRunningTotal,
    required this.enableHaptics,
    required this.touchEnabled,
    required this.onTouchBlocked,
    this.keypadFocusId,
    required this.usePersianDigits,
    required this.onCopy,
    required this.onPaste,
    required this.onClear,
    required this.onClearEntry,
    this.onSwipeDown,
    required this.onSign,
    required this.onPercent,
    required this.onDivide,
    required this.onDigit,
    required this.onMultiply,
    required this.onSubtract,
    required this.onAdd,
    required this.onDecimal,
    required this.onEquals,
    required this.onBackspace,
    required this.onMemoryAdd,
    required this.onMemorySubtract,
    required this.onMemoryRecall,
    required this.onMemoryClear,
  });

  final Calculator calc;
  final String? error;
  final bool showRunningTotal;
  final bool enableHaptics;
  final bool touchEnabled;
  final VoidCallback onTouchBlocked;
  final String? keypadFocusId;
  final bool usePersianDigits;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onClear;
  final VoidCallback onClearEntry;
  final VoidCallback? onSwipeDown;
  final VoidCallback onSign;
  final VoidCallback onPercent;
  final VoidCallback onDivide;
  final ValueChanged<String> onDigit;
  final VoidCallback onMultiply;
  final VoidCallback onSubtract;
  final VoidCallback onAdd;
  final VoidCallback onDecimal;
  final VoidCallback onEquals;
  final VoidCallback onBackspace;
  final VoidCallback onMemoryAdd;
  final VoidCallback onMemorySubtract;
  final VoidCallback onMemoryRecall;
  final VoidCallback onMemoryClear;

  @override
  Widget build(BuildContext context) {
    final calcTheme = CalcTheme.of(context);
    final layout = CalcLayout.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: calcTheme.cardGradient,
          borderRadius: BorderRadius.circular(layout.cardRadius),
          border: Border.all(color: calcTheme.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: calcTheme.cardShadowColor,
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(layout.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 32,
                child: CalcDisplayPanel(
                  display: calc.display,
                  expression: calc.expression,
                  runningTotal: showRunningTotal ? calc.runningTotal : null,
                  error: error,
                  usePersianDigits: usePersianDigits,
                  runningTotalLabel: (t) => l10n.runningTotalPreview(t),
                  displayResultLabel: (v) => l10n.semanticsDisplayResult(v),
                  displayErrorLabel: (m) => l10n.semanticsDisplayError(m),
                  backspaceLabel: l10n.semanticsBackspace,
                  canBackspace: calc.canBackspace,
                  touchEnabled: touchEnabled,
                  onTouchBlocked: onTouchBlocked,
                  onSwipeDown: onSwipeDown,
                  onBackspace: onBackspace,
                  onCopy: onCopy,
                  onPaste: onPaste,
                  copyLabel: l10n.copyAction,
                  pasteLabel: l10n.pasteAction,
                ),
              ),
              CalcMemoryBar(
                hasMemory: calc.hasMemory,
                touchEnabled: touchEnabled,
                onTouchBlocked: onTouchBlocked,
                onAdd: onMemoryAdd,
                onSubtract: onMemorySubtract,
                onRecall: onMemoryRecall,
                onClear: onMemoryClear,
              ),
              Expanded(
                flex: 64,
                child: CalcKeypad(
                  semantics: KeypadSemantics(
                    clear: l10n.semanticsClear,
                    toggleSign: l10n.semanticsToggleSign,
                    percent: l10n.semanticsPercent,
                    divide: l10n.semanticsDivide,
                    multiply: l10n.semanticsMultiply,
                    subtract: l10n.semanticsSubtract,
                    add: l10n.semanticsAdd,
                    decimal: l10n.semanticsDecimal,
                    equals: l10n.semanticsEquals,
                  ),
                  pendingOp: calc.pendingOp,
                  canEquals: calc.canEquals,
                  canSign: calc.canToggleSign,
                  canDecimal: calc.canInputDecimal,
                  canDigit: calc.canInputDigit,
                  decimalLabel: usePersianDigits ? '٫' : '.',
                  enableHaptics: enableHaptics,
                  focusedKeyId: keypadFocusId,
                  touchEnabled: touchEnabled,
                  onTouchBlocked: onTouchBlocked,
                  onClear: onClear,
                  onClearEntry: onClearEntry,
                  onSign: onSign,
                  onPercent: onPercent,
                  onDivide: onDivide,
                  onDigit: onDigit,
                  onMultiply: onMultiply,
                  onSubtract: onSubtract,
                  onAdd: onAdd,
                  onDecimal: onDecimal,
                  onEquals: onEquals,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
