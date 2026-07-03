import 'models/calc_history_entry.dart';

/// Scrollable calculation tape (newest first).
class CalcHistory {
  static const int maxEntries = 100;

  final List<CalcHistoryEntry> _entries = [];

  List<CalcHistoryEntry> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  void loadEntries(List<CalcHistoryEntry> saved) {
    _entries
      ..clear()
      ..addAll(saved.take(maxEntries));
  }

  void add(String expression, String result) {
    if (_entries.isNotEmpty &&
        _entries.first.expression == expression &&
        _entries.first.result == result) {
      return;
    }
    _entries.insert(
      0,
      CalcHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        expression: expression,
        result: result,
        at: DateTime.now(),
      ),
    );
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }

  bool removeById(String id) {
    final i = _entries.indexWhere((e) => e.id == id);
    if (i < 0) return false;
    _entries.removeAt(i);
    return true;
  }

  void clear() => _entries.clear();
}
