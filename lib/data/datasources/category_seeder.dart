import 'package:drift/drift.dart';

import 'package:xpense/data/database/app_database.dart';

class CategorySeeder {
  static Future<void> seed(AppDatabase db) async {
    final categories = [
      ('Food & Dining', 'restaurant', '#EF4444', 0),
      ('Transportation', 'directions_car', '#F59E0B', 1),
      ('Shopping', 'shopping_bag', '#10B981', 2),
      ('Entertainment', 'movie', '#8B5CF6', 3),
      ('Utilities', 'bolt', '#3B82F6', 4),
      ('Health', 'favorite', '#EC4899', 5),
      ('Education', 'school', '#06B6D4', 6),
      ('Travel', 'flight', '#6366F1', 7),
      ('Bills & Fees', 'receipt', '#84CC16', 8),
      ('Gifts & Donations', 'card_giftcard', '#F43F5E', 9),
      ('Other', 'more_horiz', '#6B7280', 10),
    ];

    for (final (name, icon, color, sort) in categories) {
      await db.into(db.categories).insert(
            CategoriesCompanion(
              id: Value(
                'cat_${name.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and')}',
              ),
              name: Value(name),
              iconName: Value(icon),
              colorHex: Value(color),
              sortOrder: Value(sort),
            ),
          );
    }
  }
}
