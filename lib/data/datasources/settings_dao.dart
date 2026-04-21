import 'package:drift/drift.dart';

import 'package:xpense/data/database/app_database.dart' as db;

class SettingsDao {
  SettingsDao(this._db);

  final db.AppDatabase _db;

  Future<String?> getString(String key) async {
    final query = _db.select(_db.appSettings)..where((s) => s.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Future<bool> getBool(
    String key, {
    bool defaultValue = false,
  }) async {
    final value = await getString(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  Future<int?> getInt(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> setString(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          db.AppSettingsCompanion(
            key: Value(key),
            value: Value(value),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> setBool(String key, {required bool value}) async {
    await setString(key, value.toString());
  }

  Future<void> setInt(String key, {required int value}) async {
    await setString(key, value.toString());
  }

  Future<void> deleteSetting(String key) async {
    await (_db.delete(_db.appSettings)..where((s) => s.key.equals(key))).go();
  }
}
