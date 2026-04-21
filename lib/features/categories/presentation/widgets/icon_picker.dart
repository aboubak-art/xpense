import 'package:flutter/material.dart';

import 'package:xpense/core/haptics/haptic_service.dart';

/// Predefined set of Material icons available for categories.
const _categoryIcons = [
  ('restaurant', Icons.restaurant),
  ('directions_car', Icons.directions_car),
  ('shopping_bag', Icons.shopping_bag),
  ('movie', Icons.movie),
  ('bolt', Icons.bolt),
  ('favorite', Icons.favorite),
  ('school', Icons.school),
  ('flight', Icons.flight),
  ('receipt', Icons.receipt),
  ('card_giftcard', Icons.card_giftcard),
  ('more_horiz', Icons.more_horiz),
  ('home', Icons.home),
  ('work', Icons.work),
  ('sports', Icons.sports),
  ('pets', Icons.pets),
  ('local_cafe', Icons.local_cafe),
  ('local_grocery_store', Icons.local_grocery_store),
  ('medical_services', Icons.medical_services),
  ('fitness_center', Icons.fitness_center),
  ('music_note', Icons.music_note),
  ('book', Icons.book),
  ('computer', Icons.computer),
  ('phone_android', Icons.phone_android),
  ('wifi', Icons.wifi),
  ('water_drop', Icons.water_drop),
  ('local_gas_station', Icons.local_gas_station),
  ('train', Icons.train),
  ('directions_bus', Icons.directions_bus),
  ('directions_bike', Icons.directions_bike),
  ('local_taxi', Icons.local_taxi),
  ('hotel', Icons.hotel),
  ('beach_access', Icons.beach_access),
  ('park', Icons.park),
  ('theaters', Icons.theaters),
  ('gamepad', Icons.gamepad),
  ('shopping_cart', Icons.shopping_cart),
  ('attach_money', Icons.attach_money),
  ('account_balance', Icons.account_balance),
  ('savings', Icons.savings),
  ('trending_up', Icons.trending_up),
  ('emoji_events', Icons.emoji_events),
  ('celebration', Icons.celebration),
];

/// Picker grid for category icons.
class IconPicker extends StatelessWidget {
  const IconPicker({
    required this.selectedIconName,
    required this.onSelect,
    this.color = Colors.blue,
    super.key,
  });

  final String? selectedIconName;
  final ValueChanged<String> onSelect;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _categoryIcons.length,
      itemBuilder: (context, index) {
        final (name, icon) = _categoryIcons[index];
        final isSelected = name == selectedIconName;

        return InkWell(
          onTap: () {
            HapticService.selectionClick();
            onSelect(name);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  static IconData iconDataFromName(String name) {
    for (final (n, icon) in _categoryIcons) {
      if (n == name) return icon;
    }
    return Icons.category;
  }
}
