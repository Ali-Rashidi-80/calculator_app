import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calc_history_entry.dart';

/// Persists history tape and session across app restarts (#2392 Windows issue).
class CalcPersistence {
  CalcPersistence(this._prefs);

  static const _keyHistory = 'calc_history_v1';
  static const _keySession = 'calc_session_v1';
  static const _keyMemory = 'calc_memory_v1';

  final SharedPreferences _prefs;

  static Future<CalcPersistence> load() async {
    return CalcPersistence(await SharedPreferences.getInstance());
  }

  List<CalcHistoryEntry> readHistory() {
    final raw = _prefs.getString(_keyHistory);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CalcHistoryEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.expression.isNotEmpty && e.result.isNotEmpty && e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeHistory(List<CalcHistoryEntry> entries) async {
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyHistory, json);
  }

  CalculatorSession? readSession() {
    final raw = _prefs.getString(_keySession);
    if (raw == null) return null;
    try {
      final session = CalculatorSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return session.isValid ? session : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSession(CalculatorSession session) async {
    await _prefs.setString(_keySession, jsonEncode(session.toJson()));
  }

  double? readMemory() {
    if (!_prefs.containsKey(_keyMemory)) return null;
    return _prefs.getDouble(_keyMemory);
  }

  Future<void> writeMemory(double? value) async {
    if (value == null) {
      await _prefs.remove(_keyMemory);
    } else {
      await _prefs.setDouble(_keyMemory, value);
    }
  }

  Future<void> clearAll() async {
    await _prefs.remove(_keyHistory);
    await _prefs.remove(_keySession);
    await _prefs.remove(_keyMemory);
  }
}

class CalculatorSession {
  const CalculatorSession({
    required this.display,
    this.numericValue,
    this.accumulator,
    this.pendingOp,
    this.freshEntry = true,
    this.lastOp,
    this.lastOperand,
  });

  final String display;
  /// Full-precision value backing [display] after computed results.
  final double? numericValue;
  final double? accumulator;
  final String? pendingOp;
  final bool freshEntry;
  final String? lastOp;
  final double? lastOperand;

  Map<String, dynamic> toJson() => {
        'display': display,
        'numericValue': numericValue,
        'accumulator': accumulator,
        'pendingOp': pendingOp,
        'freshEntry': freshEntry,
        'lastOp': lastOp,
        'lastOperand': lastOperand,
      };

  factory CalculatorSession.fromJson(Map<String, dynamic> json) {
    return CalculatorSession(
      display: json['display'] as String? ?? '0',
      numericValue: _finiteDouble(json['numericValue']),
      accumulator: _finiteDouble(json['accumulator']),
      pendingOp: _validOp(json['pendingOp'] as String?),
      freshEntry: json['freshEntry'] as bool? ?? true,
      lastOp: _validOp(json['lastOp'] as String?),
      lastOperand: _finiteDouble(json['lastOperand']),
    );
  }

  static double? _finiteDouble(dynamic value) {
    if (value == null) return null;
    final d = (value as num).toDouble();
    if (d.isNaN || d.isInfinite) return null;
    return d;
  }

  static String? _validOp(String? op) {
    if (op == null) return null;
    return switch (op) {
      '+' || '-' || '×' || '÷' => op,
      _ => null,
    };
  }

  /// Reject malformed snapshots (#2458-style invariant violations).
  bool get isValid {
    if (display.isEmpty || display.length > 64) return false;
    if (numericValue != null && (numericValue!.isNaN || numericValue!.isInfinite)) {
      return false;
    }
    if (accumulator != null && (accumulator!.isNaN || accumulator!.isInfinite)) {
      return false;
    }
    if (lastOperand != null && (lastOperand!.isNaN || lastOperand!.isInfinite)) {
      return false;
    }
    if (pendingOp != null && accumulator == null) return false;
    if (lastOp != null && lastOperand == null) return false;
    if (lastOp == null && lastOperand != null) return false;
    return true;
  }
}
