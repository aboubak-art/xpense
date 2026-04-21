import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/data/database/app_database.dart';
import 'package:xpense/data/datasources/settings_dao.dart';

void main() {
  late AppDatabase db;
  late SettingsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SettingsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsDao', () {
    test('getString returns null for missing key', () async {
      expect(await dao.getString('missing'), isNull);
    });

    test('setString and getString roundtrip', () async {
      await dao.setString('theme', 'dark');
      expect(await dao.getString('theme'), 'dark');
    });

    test('setString updates existing value', () async {
      await dao.setString('theme', 'light');
      await dao.setString('theme', 'dark');
      expect(await dao.getString('theme'), 'dark');
    });

    test('getBool returns default for missing key', () async {
      expect(await dao.getBool('notifications'), false);
      expect(
        await dao.getBool('notifications', defaultValue: true),
        true,
      );
    });

    test('setBool and getBool roundtrip', () async {
      await dao.setBool('notifications', value: true);
      expect(await dao.getBool('notifications'), true);

      await dao.setBool('notifications', value: false);
      expect(await dao.getBool('notifications'), false);
    });

    test('setInt and getInt roundtrip', () async {
      await dao.setInt('daily_limit', value: 5000);
      expect(await dao.getInt('daily_limit'), 5000);
    });

    test('deleteSetting removes key', () async {
      await dao.setString('temp', 'value');
      expect(await dao.getString('temp'), 'value');

      await dao.deleteSetting('temp');
      expect(await dao.getString('temp'), isNull);
    });
  });
}
