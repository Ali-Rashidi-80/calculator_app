import 'package:calculator_app/ui/calc_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalcLayout breakpoints', () {
    test('compact phone 320px', () {
      const layout = CalcLayout(Size(320, 568));
      expect(layout.isCompact, isTrue);
      expect(layout.showSideHistory, isFalse);
      expect(layout.buttonFontSize, 20);
    });

    test('standard phone 390px', () {
      const layout = CalcLayout(Size(390, 844));
      expect(layout.isCompact, isFalse);
      expect(layout.isPhone, isTrue);
      expect(layout.showSideHistory, isFalse);
    });

    test('tablet portrait 768px', () {
      const layout = CalcLayout(Size(768, 1024));
      expect(layout.isTablet, isTrue);
      expect(layout.showSideHistory, isFalse);
      expect(layout.showKeyboardShortcutsButton, isFalse);
      expect(layout.maxContentWidth, 440);
    });

    test('desktop side history 1280px', () {
      const layout = CalcLayout(Size(1280, 800));
      expect(layout.showSideHistory, isTrue);
      expect(layout.showKeyboardShortcutsButton, isTrue);
      expect(layout.isWideDesktop, isTrue);
    });

    test('landscape phone uses compact height', () {
      const layout = CalcLayout(Size(667, 375));
      expect(layout.isLandscapePhone, isTrue);
      expect(layout.maxContentHeight, lessThanOrEqualTo(380));
    });

    test('touch target minimum 48dp', () {
      const layout = CalcLayout(Size(320, 568));
      expect(layout.minTouchTarget, 48);
    });
  });
}
