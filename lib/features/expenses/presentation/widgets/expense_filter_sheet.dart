import 'package:flutter/material.dart';

import 'package:xpense/domain/entities/category.dart';

class ExpenseFilterSheet extends StatefulWidget {
  const ExpenseFilterSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedSortBy,
    required this.onApply,
    super.key,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final String selectedSortBy;
  final void Function(String? categoryId, String sortBy) onApply;

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  String? _categoryId;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _categoryId = widget.selectedCategoryId;
    _sortBy = widget.selectedSortBy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Sort & Filter',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sort by',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _SortChip(
                  label: 'Date',
                  value: 'date',
                  selected: _sortBy == 'date',
                  onSelected: (v) => setState(() => _sortBy = v),
                ),
                _SortChip(
                  label: 'Amount',
                  value: 'amount',
                  selected: _sortBy == 'amount',
                  onSelected: (v) => setState(() => _sortBy = v),
                ),
                _SortChip(
                  label: 'Category',
                  value: 'category',
                  selected: _sortBy == 'category',
                  onSelected: (v) => setState(() => _sortBy = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _categoryId == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                ),
                ...widget.categories.map((cat) => ChoiceChip(
                      label: Text(cat.name),
                      selected: _categoryId == cat.id,
                      onSelected: (_) => setState(
                        () => _categoryId = cat.id,
                      ),
                    ),),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(_categoryId, _sortBy);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
  }
}
