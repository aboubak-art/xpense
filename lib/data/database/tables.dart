import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get categoryId => text()();
  TextColumn get note => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get period => text()(); // monthly, weekly, daily, custom
  TextColumn get categoryId => text().nullable()(); // null = overall budget
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get rolloverUnused =>
      boolean().withDefault(const Constant(false))();
  IntColumn get alertThresholdPercent =>
      integer().withDefault(const Constant(80))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {key};
}

class RecurringExpenses extends Table {
  TextColumn get id => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get categoryId => text()();
  TextColumn get note => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get frequency =>
      text()(); // daily, weekly, bi-weekly, monthly, quarterly, yearly, custom
  TextColumn get frequencyRule => text().nullable()(); // custom cron-like rule
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get maxOccurrences => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
