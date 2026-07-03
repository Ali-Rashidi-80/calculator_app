import '../services/calc_persistence.dart';

/// In-memory snapshot for undo/redo (Kalkyl / Windows UX).
class CalcUndoSnapshot {
  const CalcUndoSnapshot({
    required this.session,
    this.memory,
  });

  final CalculatorSession session;
  final double? memory;
}
