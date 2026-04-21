import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('appName is Xpense', () {
      expect(AppConstants.appName, 'Xpense');
    });

    test('appVersion is 1.0.0', () {
      expect(AppConstants.appVersion, '1.0.0');
    });

    test('databaseName is xpense.db', () {
      expect(AppConstants.databaseName, 'xpense.db');
    });

    test('animation durations are correct', () {
      expect(
        AppConstants.shortAnimationDuration,
        const Duration(milliseconds: 150),
      );
      expect(
        AppConstants.mediumAnimationDuration,
        const Duration(milliseconds: 300),
      );
      expect(
        AppConstants.longAnimationDuration,
        const Duration(milliseconds: 500),
      );
    });

    test('layout constants are positive', () {
      expect(AppConstants.defaultPadding, 16);
      expect(AppConstants.smallPadding, 8);
      expect(AppConstants.largePadding, 24);
      expect(AppConstants.defaultRadius, 12);
      expect(AppConstants.cardRadius, 16);
    });

    test('performance constants are positive', () {
      expect(AppConstants.pageSize, greaterThan(0));
      expect(AppConstants.maxRecentCategories, greaterThan(0));
    });
  });
}
