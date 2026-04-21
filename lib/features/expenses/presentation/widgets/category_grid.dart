import 'package:flutter/material.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/utils/color_utils.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/features/categories/presentation/widgets/icon_picker.dart';

/// A grid of category chips for selecting an expense category.
/// Recent categories appear first, followed by the full list.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat.id == selectedId;
        final color = hexToColor(cat.colorHex);

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconPicker.iconDataFromName(cat.iconName),
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(cat.name),
            ],
          ),
          selected: isSelected,
          onSelected: (_) {
            HapticService.selectionClick();
            onSelect(cat);
          },
          selectedColor: color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide.none
                : BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

}
