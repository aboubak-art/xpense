import 'package:flutter/material.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/domain/entities/category.dart';

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
        final color = _hexToColor(cat.colorHex);

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFromName(cat.iconName),
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

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _iconFromName(String name) {
    return switch (name) {
      'restaurant' => Icons.restaurant,
      'directions_car' => Icons.directions_car,
      'shopping_bag' => Icons.shopping_bag,
      'movie' => Icons.movie,
      'bolt' => Icons.bolt,
      'favorite' => Icons.favorite,
      'school' => Icons.school,
      'flight' => Icons.flight,
      'receipt' => Icons.receipt,
      'card_giftcard' => Icons.card_giftcard,
      'more_horiz' => Icons.more_horiz,
      _ => Icons.category,
    };
  }
}
