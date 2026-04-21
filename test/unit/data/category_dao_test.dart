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

  group('CategoryDao', () {
    test('create returns created category', () async {
      const input = CategoryInput(
        name: 'Food',
        iconName: 'restaurant',
        colorHex: '#FF0000',
      );

      final category = await dao.create(input);

      expect(category.name, 'Food');
      expect(category.iconName, 'restaurant');
      expect(category.colorHex, '#FF0000');
      expect(category.isIncome, false);
      expect(category.isArchived, false);
      expect(category.sortOrder, 0);
      expect(category.parentId, isNull);
      expect(category.deletedAt, isNull);
    });

    test('getById returns category after creation', () async {
      const input = CategoryInput(
        name: 'Transport',
        iconName: 'car',
        colorHex: '#00FF00',
      );
      final created = await dao.create(input);

      final fetched = await dao.getById(created.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
      expect(fetched.name, 'Transport');
    });

    test('getById returns null for non-existent id', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });

    test('getAll returns all non-deleted categories', () async {
      await dao.create(
        const CategoryInput(
          name: 'A',
          iconName: 'icon_a',
          colorHex: '#000000',
        ),
      );
      await dao.create(
        const CategoryInput(
          name: 'B',
          iconName: 'icon_b',
          colorHex: '#FFFFFF',
        ),
      );

      final all = await dao.getAll();

      expect(all.length, 2);
    });

    test('getAll excludes archived by default', () async {
      await dao.create(
        const CategoryInput(
          name: 'Active',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );
      await dao.create(
        const CategoryInput(
          name: 'Archived',
          iconName: 'icon',
          colorHex: '#000000',
          isArchived: true,
        ),
      );

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Active');

      final withArchived = await dao.getAll(includeArchived: true);
      expect(withArchived.length, 2);
    });

    test('updateCategory modifies category', () async {
      final created = await dao.create(
        const CategoryInput(
          name: 'Old',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      await dao.updateCategory(
        created.id,
        const CategoryInput(
          name: 'New',
          iconName: 'new_icon',
          colorHex: '#FFFFFF',
        ),
      );

      final updated = await dao.getById(created.id);
      expect(updated!.name, 'New');
      expect(updated.iconName, 'new_icon');
      expect(updated.colorHex, '#FFFFFF');
    });

    test('deleteCategory performs soft delete', () async {
      final created = await dao.create(
        const CategoryInput(
          name: 'ToDelete',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      await dao.deleteCategory(created.id);

      final fetched = await dao.getById(created.id);
      expect(fetched, isNull);

      final all = await dao.getAll();
      expect(all.isEmpty, true);
    });

    test('count returns correct number', () async {
      expect(await dao.count(), 0);
      await dao.create(
        const CategoryInput(
          name: 'One',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );
      expect(await dao.count(), 1);
    });
  });
}
