import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String iconName,
    required String colorHex,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isIncome,
    @Default(false) bool isArchived,
    @Default(0) int sortOrder,
    String? parentId,
    DateTime? deletedAt,
  }) = _Category;
}

@freezed
class CategoryInput with _$CategoryInput {
  const factory CategoryInput({
    required String name,
    required String iconName,
    required String colorHex,
    @Default(false) bool isIncome,
    @Default(false) bool isArchived,
    @Default(0) int sortOrder,
    String? parentId,
  }) = _CategoryInput;
}
