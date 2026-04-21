import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/data/database/app_database.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/domain/entities/category.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = CategoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao extended methods', () {
    test('getSubcategories returns only children of parent', () async {
      final parent = await dao.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      await dao.create(
        CategoryInput(
          name: 'Fast Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
          parentId: parent.id,
        ),
      );

      await dao.create(
        const CategoryInput(
          name: 'Transport',
          iconName: 'car',
          colorHex: '#0000FF',
        ),
      );

      final subs = await dao.getSubcategories(parent.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'Fast Food');
    });

    test('getSubcategories excludes archived subcategories', () async {
      final parent = await dao.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      await dao.create(
        CategoryInput(
          name: 'Active Sub',
          iconName: 'restaurant',
          colorHex: '#EF4444',
          parentId: parent.id,
          isArchived: false,
        ),
      );

      await dao.create(
        CategoryInput(
          name: 'Archived Sub',
          iconName: 'restaurant',
          colorHex: '#EF4444',
          parentId: parent.id,
          isArchived: true,
        ),
      );

      final subs = await dao.getSubcategories(parent.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'Active Sub');
    });

    test('updateSortOrder changes sort order', () async {
      final category = await dao.create(
        const CategoryInput(
          name: 'Test',
          iconName: 'icon',
          colorHex: '#000000',
          sortOrder: 0,
        ),
      );

      await dao.updateSortOrder(category.id, 5);

      final updated = await dao.getById(category.id);
      expect(updated!.sortOrder, 5);
    });

    test('toggleArchive toggles archive status', () async {
      final category = await dao.create(
        const CategoryInput(
          name: 'Test',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      expect(category.isArchived, false);

      await dao.toggleArchive(category.id, true);
      var updated = await dao.getById(category.id);
      expect(updated!.isArchived, true);

      await dao.toggleArchive(category.id, false);
      updated = await dao.getById(category.id);
      expect(updated!.isArchived, false);
    });

    test('parentId is persisted correctly', () async {
      final parent = await dao.create(
        const CategoryInput(
          name: 'Parent',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      final child = await dao.create(
        CategoryInput(
          name: 'Child',
          iconName: 'icon',
          colorHex: '#000000',
          parentId: parent.id,
        ),
      );

      expect(child.parentId, parent.id);

      final fetched = await dao.getById(child.id);
      expect(fetched!.parentId, parent.id);
    });

    test('isIncome is persisted correctly', () async {
      final income = await dao.create(
        const CategoryInput(
          name: 'Salary',
          iconName: 'work',
          colorHex: '#000000',
          isIncome: true,
        ),
      );

      expect(income.isIncome, true);

      final fetched = await dao.getById(income.id);
      expect(fetched!.isIncome, true);
    });
  });
}
