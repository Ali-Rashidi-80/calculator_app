import 'package:flutter/material.dart';

import '../calc_rtl.dart';
import 'calc_button.dart';
import 'keypad_semantics.dart';

class CalcKeypad extends StatelessWidget {
  const CalcKeypad({
    super.key,
    required this.onClear,
    this.onClearEntry,
    required this.onSign,
    required this.onPercent,
    required this.onDivide,
    required this.onDigit,
    required this.onMultiply,
    required this.onSubtract,
    required this.onAdd,
    required this.onDecimal,
    required this.onEquals,
    required this.semantics,
    this.pendingOp,
    this.enableHaptics = true,
    this.focusedKeyId,
    this.touchEnabled = true,
    this.onTouchBlocked,
    this.canEquals = true,
    this.canSign = true,
    this.canDecimal = true,
    this.canDigit = true,
    this.decimalLabel = '.',
  });

  final VoidCallback onClear;
  final VoidCallback? onClearEntry;
  final VoidCallback onSign;
  final VoidCallback onPercent;
  final VoidCallback onDivide;
  final ValueChanged<String> onDigit;
  final VoidCallback onMultiply;
  final VoidCallback onSubtract;
  final VoidCallback onAdd;
  final VoidCallback onDecimal;
  final VoidCallback onEquals;
  final KeypadSemantics semantics;
  final String? pendingOp;
  final bool enableHaptics;
  final String? focusedKeyId;
  final bool touchEnabled;
  final VoidCallback? onTouchBlocked;
  final bool canEquals;
  final bool canSign;
  final bool canDecimal;
  final bool canDigit;
  final String decimalLabel;

  @override
  Widget build(BuildContext context) {
    return calcNumbersLtr(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 12),
        child: Column(
        children: [
          _row([
            _key('C', 'clear', onClear,
                kind: CalcButtonKind.utility,
                semanticsLabel: semantics.clear,
                onLongPress: onClearEntry),
            _key('±', 'sign', onSign,
                kind: CalcButtonKind.utility,
                semanticsLabel: semantics.toggleSign,
                enabled: canSign),
            _key('%', 'pct', onPercent,
                kind: CalcButtonKind.utility,
                semanticsLabel: semantics.percent),
            _key('÷', 'div', onDivide,
                kind: CalcButtonKind.operator,
                semanticsLabel: semantics.divide,
                op: '÷'),
          ]),
          _row([
            _key('7', '7', () => onDigit('7'), enabled: canDigit),
            _key('8', '8', () => onDigit('8'), enabled: canDigit),
            _key('9', '9', () => onDigit('9'), enabled: canDigit),
            _key('×', 'mul', onMultiply, kind: CalcButtonKind.operator, semanticsLabel: semantics.multiply, op: '×'),
          ]),
          _row([
            _key('4', '4', () => onDigit('4'), enabled: canDigit),
            _key('5', '5', () => onDigit('5'), enabled: canDigit),
            _key('6', '6', () => onDigit('6'), enabled: canDigit),
            _key('-', 'sub', onSubtract, kind: CalcButtonKind.operator, semanticsLabel: semantics.subtract, op: '-'),
          ]),
          _row([
            _key('1', '1', () => onDigit('1'), enabled: canDigit),
            _key('2', '2', () => onDigit('2'), enabled: canDigit),
            _key('3', '3', () => onDigit('3'), enabled: canDigit),
            _key('+', 'add', onAdd, kind: CalcButtonKind.operator, semanticsLabel: semantics.add, op: '+'),
          ]),
          _row([
            _key('0', '0', () => onDigit('0'), flex: 2, enabled: canDigit),
            _key(decimalLabel, 'dot', onDecimal,
                semanticsLabel: semantics.decimal, enabled: canDecimal),
            _key('=', 'eq', onEquals,
                kind: CalcButtonKind.equals,
                semanticsLabel: semantics.equals,
                enabled: canEquals),
          ]),
        ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys,
      ),
    );
  }

  Widget _key(
    String label,
    String id,
    VoidCallback onTap, {
    CalcButtonKind kind = CalcButtonKind.digit,
    int flex = 1,
    String? semanticsLabel,
    String? op,
    VoidCallback? onLongPress,
    bool enabled = true,
  }) {
    return CalcButton(
      key: Key('btn_$id'),
      label: label,
      id: id,
      onTap: onTap,
      onLongPress: onLongPress,
      kind: kind,
      flex: flex,
      semanticsLabel: semanticsLabel,
      selected: op != null && pendingOp == op,
      keyboardFocused: focusedKeyId == id,
      touchEnabled: touchEnabled,
      enabled: enabled,
      onTouchBlocked: onTouchBlocked,
      enableHaptics: enableHaptics,
    );
  }
}
