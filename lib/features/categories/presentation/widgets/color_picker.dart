import 'package:flutter/material.dart';

import 'package:xpense/core/haptics/haptic_service.dart';

/// Predefined color palette for categories.
const _categoryColors = [
  '#EF4444',
  '#F97316',
  '#F59E0B',
  '#84CC16',
  '#10B981',
  '#06B6D4',
  '#3B82F6',
  '#6366F1',
  '#8B5CF6',
  '#EC4899',
  '#F43F5E',
  '#6B7280',
  '#0F172A',
];

/// Compact color picker for categories.
class ColorPicker extends StatelessWidget {
  const ColorPicker({
    required this.selectedColorHex,
    required this.onSelect,
    super.key,
  });

  final String? selectedColorHex;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _categoryColors.map((hex) {
        final color = _hexToColor(hex);
        final isSelected = hex == selectedColorHex;

        return GestureDetector(
          onTap: () {
            HapticService.selectionClick();
            onSelect(hex);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  static Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
