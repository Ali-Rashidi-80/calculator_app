import 'package:calculator_app/ui/calc_keypad_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalcKeypadGrid navigation', () {
    test('home and end keys', () {
      expect(CalcKeypadGrid.homeKey, '7');
      expect(CalcKeypadGrid.endKey, 'eq');
    });

    test('arrow down from 7 goes to 4', () {
      expect(CalcKeypadGrid.move('7', dRow: 1, dCol: 0), '4');
    });

    test('arrow right from 7 goes to 8', () {
      expect(CalcKeypadGrid.move('7', dRow: 0, dCol: 1), '8');
    });

    test('arrow right from 0 wide key goes to dot', () {
      expect(CalcKeypadGrid.move('0', dRow: 0, dCol: 1), 'dot');
    });

    test('arrow left from dot goes to 0', () {
      expect(CalcKeypadGrid.move('dot', dRow: 0, dCol: -1), '0');
    });

    test('end key is reachable from home via grid', () {
      var id = CalcKeypadGrid.homeKey;
      id = CalcKeypadGrid.move(id, dRow: 1, dCol: 0);
      expect(id, '4');
      id = CalcKeypadGrid.move(id, dRow: 1, dCol: 0);
      expect(id, '1');
      id = CalcKeypadGrid.move(id, dRow: 1, dCol: 0);
      expect(id, '0');
      id = CalcKeypadGrid.move(id, dRow: 0, dCol: 1);
      expect(id, 'dot');
      id = CalcKeypadGrid.move(id, dRow: 0, dCol: 1);
      expect(id, CalcKeypadGrid.endKey);
    });
  });
}
