class CalcHistoryEntry {
  const CalcHistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
    required this.at,
  });

  final String id;
  final String expression;
  final String result;
  final DateTime at;

  String get line => '$expression = $result';

  Map<String, dynamic> toJson() => {
        'id': id,
        'expression': expression,
        'result': result,
        'at': at.toIso8601String(),
      };

  factory CalcHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CalcHistoryEntry(
      id: json['id'] as String? ?? json['at'] as String? ?? '',
      expression: json['expression'] as String,
      result: json['result'] as String,
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
