import 'calc_history.dart';
import 'models/calc_history_entry.dart';
import 'models/calc_undo_snapshot.dart';
import 'services/calc_persistence.dart';

import 'utils/digit_locale.dart';
import 'utils/display_format.dart';
import 'utils/paste_parser.dart';

/// Pure calculator logic — easy to unit test without Flutter widgets.
class Calculator {
  static const int maxDisplayLength = 16;
  static const double _sciThresholdHigh = 1e10;
  static const double _sciThresholdLow = 1e-7;

  String _display = '0';

  /// Full-precision value when display came from a computed result (not typed digits).
  double? _numericValue;
  double? _accumulator;
  String? _pendingOp;
  bool _freshEntry = true;
  String? _lastOp;
  double? _lastOperand;
  double? _memory;
  final CalcHistory history = CalcHistory();
  static const int _maxUndo = 32;
  final List<CalcUndoSnapshot> _undoStack = [];
  final List<CalcUndoSnapshot> _redoStack = [];
  bool _undoSuspended = false;
  bool _lastPasteTrimmed = false;

  /// True when the last successful paste had digits trimmed (MS #162).
  bool get lastPasteTrimmed => _lastPasteTrimmed;

  String get display => _display;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  String? get pendingOp => _pendingOp;

  /// Equals is meaningful only with a pending chain or repeat-last-op state.
  bool get canEquals =>
      (_accumulator != null && _pendingOp != null) ||
      (_lastOp != null && _lastOperand != null);

  bool get canToggleSign =>
      _display != '0' && _display != '-0' && _display != '0.';

  bool get canInputDecimal =>
      !_display.contains('.') &&
      !(_atMaxLength && !_freshEntry && _display != '0');

  bool get canInputDigit => !(_atMaxLength && !_freshEntry && _display != '0');

  bool get canBackspace => !_freshEntry;

  bool get canMemoryRecall => _memory != null;

  bool get canMemoryClear => _memory != null;

  bool get hasMemory => _memory != null;

  double? get memoryValue => _memory;

  String get expression {
    if (_accumulator == null || _pendingOp == null) return '';
    final left = _format(_accumulator!);
    if (!_freshEntry) {
      return '$left $_pendingOp $_display';
    }
    return '$left $_pendingOp';
  }

  /// Live preview of `=` while entering the second operand (iOS 17 running-total UX).
  String? get runningTotal {
    if (_accumulator == null || _pendingOp == null || _freshEntry) {
      return null;
    }
    final value = _parseDisplay();
    if (value == null) return null;
    try {
      return _format(_apply(_accumulator!, value, _pendingOp!));
    } on CalculatorError {
      return null;
    }
  }

  /// Restore from disk after app restart.
  void restoreSession(CalculatorSession session, {double? memory}) {
    _display = session.display;
    _numericValue = session.numericValue;
    _accumulator = session.accumulator;
    _pendingOp = session.pendingOp;
    _freshEntry = session.freshEntry;
    _lastOp = session.lastOp;
    _lastOperand = session.lastOperand;
    _memory = memory;
  }

  CalculatorSession exportSession() => CalculatorSession(
    display: _display,
    numericValue: _numericValue,
    accumulator: _accumulator,
    pendingOp: _pendingOp,
    freshEntry: _freshEntry,
    lastOp: _lastOp,
    lastOperand: _lastOperand,
  );

  void loadHistory(List<CalcHistoryEntry> entries) {
    history.loadEntries(entries);
  }

  bool deleteHistoryEntry(String id) => history.removeById(id);

  /// Load a past result into the display (history reuse).
  void loadResult(String resultText) {
    final value = parseNumericText(resultText);
    if (value == null) return;
    _recordUndo();
    _setDisplayValue(value);
    _freshEntry = true;
    _accumulator = null;
    _pendingOp = null;
    _lastOp = null;
    _lastOperand = null;
  }

  /// Parse display/history text — Persian digits, ٫/، decimal, unicode minus.
  static double? parseNumericText(String raw) {
    final normalized = DigitLocale.normalizePaste(
      DigitLocale.normalizeToAscii(raw.trim()),
    );
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void deleteLast() {
    if (_freshEntry) return;
    _recordUndo();
    _numericValue = null;
    if (_display.length <= 1 ||
        (_display.length == 2 && _display.startsWith('-'))) {
      _display = '0';
      _freshEntry = true;
      return;
    }
    _display = _display.substring(0, _display.length - 1);
  }

  void inputDigit(String digit) {
    final d = DigitLocale.normalizeToAscii(digit);
    if (d.length != 1 || d.codeUnitAt(0) < 0x30 || d.codeUnitAt(0) > 0x39) {
      return;
    }
    if (_atMaxLength && !_freshEntry && _display != '0') return;
    if (_freshEntry || _display == '0') {
      _recordUndo();
      _numericValue = null;
      _display = d;
      _freshEntry = false;
    } else {
      _numericValue = null;
      _display += d;
    }
  }

  void inputDecimal() {
    if (_freshEntry) {
      _recordUndo();
      _numericValue = null;
      _display = '0.';
      _freshEntry = false;
      return;
    }
    if (!_display.contains('.')) {
      if (_atMaxLength) return;
      _numericValue = null;
      _display += '.';
    }
  }

  void setOperation(String op) {
    final value = _parseDisplay();
    if (value == null) return;
    _recordUndo();

    if (_accumulator != null && _pendingOp != null && !_freshEntry) {
      _accumulator = _apply(_accumulator!, value, _pendingOp!);
      _setDisplayValue(_accumulator!);
    } else {
      _accumulator ??= value;
    }

    _pendingOp = op;
    _freshEntry = true;
  }

  void equals() {
    if (_accumulator != null && _pendingOp != null) {
      final value = _parseDisplay();
      if (value == null) return;
      _recordUndo();

      final left = _format(_accumulator!);
      final op = _pendingOp!;
      final right = _format(value);
      final result = _apply(_accumulator!, value, op);
      final formatted = _format(result);

      history.add('$left $op $right', formatted);
      _lastOp = op;
      _lastOperand = value;
      _setDisplayValue(result, formatted: formatted);
      _accumulator = null;
      _pendingOp = null;
      _freshEntry = true;
      return;
    }

    if (_lastOp == null || _lastOperand == null) return;

    final current = _parseDisplay();
    if (current == null) return;
    _recordUndo();

    final left = _format(current);
    final right = _format(_lastOperand!);
    final result = _apply(current, _lastOperand!, _lastOp!);
    final formatted = _format(result);

    history.add('$left $_lastOp $right', formatted);
    _setDisplayValue(result, formatted: formatted);
    _freshEntry = true;
  }

  /// Full reset (AC / C).
  void clear() {
    _recordUndo();
    _display = '0';
    _numericValue = null;
    _accumulator = null;
    _pendingOp = null;
    _freshEntry = true;
    _lastOp = null;
    _lastOperand = null;
  }

  /// Clear entry only — keeps pending operation (CE).
  void clearEntry() {
    _recordUndo();
    _display = '0';
    _numericValue = null;
    _freshEntry = true;
  }

  void toggleSign() {
    if (_display == '0') return;
    _recordUndo();
    _numericValue = null;
    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-$_display';
    }
  }

  /// Windows Standard: `50+10%` → 5 on display, `=` → 55.
  /// For ×/÷ pending ops, `%` is `value / 100` only (`50×10%` → 0.1, `=` → 5).
  /// Plain `%` divides current display by 100.
  void percent() {
    final value = _parseDisplay();
    if (value == null) return;
    _recordUndo();

    if (_accumulator != null && _pendingOp != null) {
      final next = switch (_pendingOp!) {
        '+' || '-' => _accumulator! * value / 100,
        '×' || '÷' || '*' || '/' => value / 100,
        _ => value / 100,
      };
      _setDisplayValue(next);
      _freshEntry = true;
      return;
    }

    _setDisplayValue(value / 100);
    _freshEntry = true;
  }

  void memoryAdd() {
    final value = _parseDisplay();
    if (value == null) return;
    _memory = (_memory ?? 0) + value;
  }

  void memorySubtract() {
    final value = _parseDisplay();
    if (value == null) return;
    _memory = (_memory ?? 0) - value;
  }

  void memoryRecall() {
    if (_memory == null) return;
    _recordUndo();
    _setDisplayValue(_memory!);
    _freshEntry = true;
  }

  void memoryClear() => _memory = null;

  /// Replace memory with current display (Windows Ctrl+M / MS).
  void memoryStore() {
    final value = _parseDisplay();
    if (value == null) return;
    _memory = value;
  }

  void clearHistory() => history.clear();

  /// Plain decimal for clipboard — never scientific (iOS 18 accounting #255975372).
  String get copyPlainText {
    String raw;
    if (!_display.contains('e') && !_display.contains('E')) {
      raw = _display;
    } else {
      final value = _numericValue ?? _parseDisplay();
      if (value == null || value.isNaN || value.isInfinite) {
        raw = _display;
      } else {
        raw = DisplayFormat.formatPlain(value);
      }
    }
    return DigitLocale.toClipboardAscii(raw);
  }

  /// Plain-text export of the history tape (newest first, ASCII for clipboard).
  String exportHistoryText() {
    if (history.isEmpty) return '';
    return history.entries
        .map(
          (e) =>
              '${DigitLocale.toClipboardAscii(e.expression)} = ${DigitLocale.toClipboardAscii(e.result)}',
        )
        .join('\n');
  }

  /// Paste a numeric string or simple LTR expression. Returns false if invalid.
  bool pasteFromText(String raw) {
    _lastPasteTrimmed = false;
    final parsed = PasteParser.evaluateDetailed(raw);
    final value = parsed.value;
    if (value == null) return false;
    _lastPasteTrimmed = parsed.trimmed;
    if (value.isNaN) {
      throw CalculatorError.divisionByZero;
    }
    if (value.isInfinite) {
      throw CalculatorError.divisionByZero;
    }
    _recordUndo();
    _setDisplayValue(value);
    if (_accumulator != null && _pendingOp != null) {
      _freshEntry = true;
      return true;
    }
    _accumulator = null;
    _pendingOp = null;
    _freshEntry = true;
    return true;
  }

  bool get _atMaxLength {
    final digits = _display.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= maxDisplayLength;
  }

  double? _parseDisplay() {
    if (_freshEntry && _numericValue != null) return _numericValue;
    if (_display == '0.' || _display == '-0.') return 0;
    if (_display.endsWith('.')) {
      return double.tryParse(_display.substring(0, _display.length - 1));
    }
    return double.tryParse(_display);
  }

  void _setDisplayValue(double value, {String? formatted}) {
    _numericValue = value;
    _display = formatted ?? _format(value);
  }

  CalcUndoSnapshot captureSnapshot() =>
      CalcUndoSnapshot(session: exportSession(), memory: _memory);

  void restoreSnapshot(CalcUndoSnapshot snapshot) {
    _undoSuspended = true;
    restoreSession(snapshot.session, memory: snapshot.memory);
    _undoSuspended = false;
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _undoSuspended = true;
    _redoStack.add(captureSnapshot());
    restoreSnapshot(_undoStack.removeLast());
    _undoSuspended = false;
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoSuspended = true;
    _undoStack.add(captureSnapshot());
    restoreSnapshot(_redoStack.removeLast());
    _undoSuspended = false;
  }

  void _recordUndo() {
    if (_undoSuspended) return;
    _undoStack.add(captureSnapshot());
    if (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  static double _apply(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) {
          throw CalculatorError.divisionByZero;
        }
        return a / b;
      default:
        return b;
    }
  }

  static String _format(double value) {
    if (value.isNaN || value.isInfinite) {
      throw CalculatorError.overflow;
    }

    final snapped = DisplayFormat.snap(value);
    final abs = snapped.abs();
    if (abs >= _sciThresholdHigh || (abs > 0 && abs < _sciThresholdLow)) {
      final exp = snapped.toStringAsExponential(6);
      return exp
          .replaceAll(RegExp(r'0+e'), 'e')
          .replaceAll(RegExp(r'\.e'), 'e');
    }

    if (snapped == snapped.roundToDouble()) {
      return snapped.toInt().toString();
    }
    return DisplayFormat.formatPlain(snapped);
  }
}

enum CalculatorError implements Exception { divisionByZero, overflow }
