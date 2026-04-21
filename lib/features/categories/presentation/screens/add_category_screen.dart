import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/utils/color_utils.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/features/categories/presentation/providers/category_provider.dart';
import 'package:xpense/features/categories/presentation/widgets/color_picker.dart';
import 'package:xpense/features/categories/presentation/widgets/icon_picker.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({this.categoryToEdit, super.key});

  final Category? categoryToEdit;

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  late final TextEditingController _nameController;
  late String? _selectedIcon;
  late String? _selectedColor;
  late bool _isIncome;
  late String? _parentId;
  bool _saving = false;

  bool get _isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.categoryToEdit;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _selectedIcon = cat?.iconName ?? 'more_horiz';
    _selectedColor = cat?.colorHex ?? '#3B82F6';
    _isIncome = cat?.isIncome ?? false;
    _parentId = cat?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a category name')),
        );
      }
      return;
    }
    if (_selectedIcon == null || _selectedColor == null) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an icon and color')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final input = CategoryInput(
      name: name,
      iconName: _selectedIcon!,
      colorHex: _selectedColor!,
      isIncome: _isIncome,
      parentId: _parentId,
    );

    final notifier = ref.read(categoryFormNotifierProvider.notifier);

    if (_isEditing) {
      await notifier.update(widget.categoryToEdit!.id, input);
    } else {
      await notifier.create(input);
    }

    setState(() => _saving = false);

    final state = ref.read(categoryFormNotifierProvider);
    state.whenOrNull(
      data: (_) {
        HapticService.success();
        if (mounted) context.pop();
      },
      error: (e, _) {
        HapticService.error();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'New Category'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g., Groceries',
              prefixIcon: Icon(Icons.label_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          // Income/Expense toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_downward),
              ),
              ButtonSegment(
                value: true,
                label: Text('Income'),
                icon: Icon(Icons.arrow_upward),
              ),
            ],
            selected: {_isIncome},
            onSelectionChanged: (set) {
              HapticService.selectionClick();
              setState(() => _isIncome = set.first);
            },
          ),
          const SizedBox(height: 32),

          // Icon picker
          Text(
            'Icon',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          IconPicker(
            selectedIconName: _selectedIcon,
            onSelect: (name) => setState(() => _selectedIcon = name),
            color: hexToColor(_selectedColor ?? '#3B82F6'),
          ),
          const SizedBox(height: 32),

          // Color picker
          Text(
            'Color',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ColorPicker(
            selectedColorHex: _selectedColor,
            onSelect: (hex) => setState(() => _selectedColor = hex),
          ),
          const SizedBox(height: 32),

          // Save button
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save Changes' : 'Create Category'),
          ),
        ],
      ),
    );
  }

}
