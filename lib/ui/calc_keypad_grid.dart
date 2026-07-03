/// Pearson-style arrow-key grid for calculator keypad (5×4 with wide zero).
class CalcKeypadGrid {
  CalcKeypadGrid._();

  static const homeKey = '7';
  static const endKey = 'eq';

  static const _cells = <_KeypadCell>[
    _KeypadCell('clear', 0, 0),
    _KeypadCell('sign', 0, 1),
    _KeypadCell('pct', 0, 2),
    _KeypadCell('div', 0, 3),
    _KeypadCell('7', 1, 0),
    _KeypadCell('8', 1, 1),
    _KeypadCell('9', 1, 2),
    _KeypadCell('mul', 1, 3),
    _KeypadCell('4', 2, 0),
    _KeypadCell('5', 2, 1),
    _KeypadCell('6', 2, 2),
    _KeypadCell('sub', 2, 3),
    _KeypadCell('1', 3, 0),
    _KeypadCell('2', 3, 1),
    _KeypadCell('3', 3, 2),
    _KeypadCell('add', 3, 3),
    _KeypadCell('0', 4, 0, colSpan: 2),
    _KeypadCell('dot', 4, 2),
    _KeypadCell('eq', 4, 3),
  ];

  static final Map<String, _KeypadCell> _byId = {
    for (final c in _cells) c.id: c,
  };

  static bool isValidKey(String id) => _byId.containsKey(id);

  static String move(String current, {required int dRow, required int dCol}) {
    if (!_byId.containsKey(current)) return homeKey;
    final cell = _byId[current]!;

    if (dRow != 0) {
      final targetRow = (cell.row + dRow).clamp(0, 4);
      final anchorCol = cell.col + (cell.colSpan - 1) ~/ 2;
      return _cellCovering(targetRow, anchorCol)?.id ?? current;
    }

    if (dCol > 0) {
      final nextCol = cell.col + cell.colSpan;
      return _cellCovering(cell.row, nextCol)?.id ?? current;
    }
    if (dCol < 0) {
      final prevCol = cell.col - 1;
      if (prevCol < 0) return current;
      return _cellCovering(cell.row, prevCol)?.id ?? current;
    }

    return current;
  }

  static _KeypadCell? _cellCovering(int row, int col) {
    for (final c in _cells) {
      if (c.row == row && col >= c.col && col < c.col + c.colSpan) {
        return c;
      }
    }
    return null;
  }
}

class _KeypadCell {
  const _KeypadCell(this.id, this.row, this.col, {this.colSpan = 1});

  final String id;
  final int row;
  final int col;
  final int colSpan;
}
