import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme Typography & Font Centralization', () {
    test('mathNumberStyle uses local JetBrainsMono font family', () {
      final style = AppTheme.mathNumberStyle();
      expect(style.fontFamily, equals('JetBrainsMono'));
      expect(style.fontWeight, equals(FontWeight.w800));
      expect(style.fontSize, equals(38));
      expect(style.color, equals(AppTheme.darkBorder));
    });

    test('statNumberStyle uses local JetBrainsMono font family', () {
      final style = AppTheme.statNumberStyle();
      expect(style.fontFamily, equals('JetBrainsMono'));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.fontSize, equals(24));
    });

    test('answerButtonStyle uses local JetBrainsMono font family', () {
      final style = AppTheme.answerButtonStyle();
      expect(style.fontFamily, equals('JetBrainsMono'));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.fontSize, equals(26));
    });

    test('brandTitleStyle uses Baberry font family', () {
      final style = AppTheme.brandTitleStyle();
      expect(style.fontFamily, equals('Baberry'));
      expect(style.fontSize, equals(62));
    });
  });
}
