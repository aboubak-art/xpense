import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme is not null', () {
      expect(AppTheme.lightTheme, isNotNull);
    });

    test('darkTheme is not null', () {
      expect(AppTheme.darkTheme, isNotNull);
    });

    test('lightTheme uses Material3', () {
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    test('darkTheme uses Material3', () {
      expect(AppTheme.darkTheme.useMaterial3, isTrue);
    });

    test('lightTheme brightness is light', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
    });

    test('darkTheme brightness is dark', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });

    test('lightTheme scaffold background is light gray', () {
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        const Color(0xFFF8FAFC),
      );
    });

    test('darkTheme scaffold background is dark slate', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        const Color(0xFF0F172A),
      );
    });

    test('lightTheme has card theme with zero elevation', () {
      expect(AppTheme.lightTheme.cardTheme.elevation, 0);
    });

    test('darkTheme has card theme with zero elevation', () {
      expect(AppTheme.darkTheme.cardTheme.elevation, 0);
    });
  });
}
