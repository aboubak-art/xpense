abstract class AppConstants {
  static const String appName = 'Xpense';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'xpense.db';
  static const int databaseVersion = 1;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Layout
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double defaultRadius = 12;
  static const double cardRadius = 16;

  // Performance
  static const int pageSize = 50;
  static const int maxRecentCategories = 6;
}
