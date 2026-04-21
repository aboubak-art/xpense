import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/recurring_expense.dart';
import 'package:xpense/features/expenses/presentation/widgets/category_grid.dart';
import 'package:xpense/features/expenses/presentation/widgets/custom_keypad.dart';

/// Form for creating or editing a recurring expense.
/// Returns a [RecurringExpenseInput] when the user confirms.
class RecurringExpenseForm extends ConsumerStatefulWidget {
  const RecurringExpenseForm({this.expense, super.key});

  final RecurringExpense? expense;

  @override
  ConsumerState<RecurringExpenseForm> createState() =>
      _RecurringExpenseFormState();
}

class _RecurringExpenseFormState extends ConsumerState<RecurringExpenseForm> {
  late String _amountText;
  late String? _selectedCategoryId;
  late String _note;
  late String _merchant;
  late RecurringFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  int? _maxOccurrences;
  late EndCondition _endCondition;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _amountText = (expense.amountCents / 100).toStringAsFixed(2);
      _selectedCategoryId = expense.categoryId;
      _note = expense.note ?? '';
      _merchant = expense.merchant ?? '';
      _frequency = expense.frequency;
      _startDate = expense.startDate;
      _endDate = expense.endDate;
      _maxOccurrences = expense.maxOccurrences;
      _endCondition = expense.endDate != null
          ? EndCondition.onDate
          : (expense.maxOccurrences != null
              ? EndCondition.afterNTimes
              : EndCondition.never);
    } else {
      _amountText = '';
      _selectedCategoryId = null;
      _note = '';
      _merchant = '';
      _frequency = RecurringFrequency.monthly;
      _startDate = DateTime.now();
      _endCondition = EndCondition.never;
    }
  }

  void _onDigit(String digit) {
    if (_amountText.length >= 8) return;
    setState(() {
      _amountText += digit;
    });
  }

  void _onDecimal() {
    if (!_amountText.contains('.')) {
      setState(() {
        _amountText = _amountText.isEmpty ? '0.' : '$_amountText.';
      });
    }
  }

  void _onBackspace() {
    if (_amountText.isNotEmpty) {
      setState(() {
        _amountText = _amountText.substring(0, _amountText.length - 1);
      });
    }
  }

  String get _displayAmount {
    if (_amountText.isEmpty) return '0.00';
    if (_amountText == '.') return '0.';
    return _amountText;
  }

  int? get _amountCents {
    if (_amountText.isEmpty) return null;
    final parsed = double.tryParse(_amountText);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  void _onSave() {
    final cents = _amountCents;
    if (cents == null || cents <= 0) {
      unawaited(HapticService.error());
      return;
    }
    if (_selectedCategoryId == null) {
      unawaited(HapticService.error());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }

    final input = RecurringExpenseInput(
      amountCents: cents,
      categoryId: _selectedCategoryId!,
      frequency: _frequency,
      startDate: _startDate,
      note: _note.isNotEmpty ? _note : null,
      merchant: _merchant.isNotEmpty ? _merchant : null,
      endDate: _endCondition == EndCondition.onDate ? _endDate : null,
      maxOccurrences: _endCondition == EndCondition.afterNTimes
          ? _maxOccurrences
          : null,
    );

    unawaited(HapticService.success());
    Navigator.pop(context, input);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoriesAsync = ref.watch(_formCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? 'Edit Recurring' : 'New Recurring',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _onSave,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Amount
                    Center(
                      child: Text(
                        '\$$_displayAmount',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category
                    categoriesAsync.when(
                      data: (categories) => CategoryGrid(
                        categories: categories,
                        selectedId: _selectedCategoryId,
                        onSelect: (cat) {
                          setState(() => _selectedCategoryId = cat.id);
                        },
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 24),
                    // Frequency
                    _buildSectionTitle('Frequency'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RecurringFrequency.values.map((freq) {
                        final isSelected = _frequency == freq;
                        return ChoiceChip(
                          label: Text(_frequencyLabel(freq)),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _frequency = freq);
                          },
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Dates
                    _buildSectionTitle('Start Date'),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_formatDate(_startDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDate(isStart: true),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End condition
                    _buildSectionTitle('End Condition'),
                    Column(
                      children: [
                        RadioListTile<EndCondition>(
                          title: const Text('Never'),
                          value: EndCondition.never,
                          groupValue: _endCondition,
                          onChanged: (v) => setState(() => _endCondition = v!),
                        ),
                        RadioListTile<EndCondition>(
                          title: const Text('After a number of times'),
                          value: EndCondition.afterNTimes,
                          groupValue: _endCondition,
                          onChanged: (v) => setState(() => _endCondition = v!),
                        ),
                        if (_endCondition == EndCondition.afterNTimes)
                          Padding(
                            padding: const EdgeInsets.only(left: 56, right: 16),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Number of times',
                                hintText: '12',
                              ),
                              onChanged: (v) {
                                setState(() => _maxOccurrences = int.tryParse(v));
                              },
                              controller: TextEditingController(
                                text: _maxOccurrences?.toString() ?? '',
                              ),
                            ),
                          ),
                        RadioListTile<EndCondition>(
                          title: const Text('On a specific date'),
                          value: EndCondition.onDate,
                          groupValue: _endCondition,
                          onChanged: (v) => setState(() => _endCondition = v!),
                        ),
                        if (_endCondition == EndCondition.onDate)
                          Padding(
                            padding: const EdgeInsets.only(left: 56, right: 16),
                            child: ListTile(
                              leading: const Icon(Icons.event),
                              title: Text(
                                _endDate != null
                                    ? _formatDate(_endDate!)
                                    : 'Select end date',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _pickDate(isStart: false),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Optional details
                    _buildSectionTitle('Details (Optional)'),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'e.g., Netflix subscription',
                      ),
                      onChanged: (v) => _note = v,
                      controller: TextEditingController(text: _note),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Merchant',
                        hintText: 'e.g., Netflix',
                      ),
                      onChanged: (v) => _merchant = v,
                      controller: TextEditingController(text: _merchant),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Keypad
              CustomKeypad(
                onDigit: _onDigit,
                onDecimal: _onDecimal,
                onBackspace: _onBackspace,
                onDone: _onSave,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  String _frequencyLabel(RecurringFrequency freq) {
    return switch (freq) {
      RecurringFrequency.daily => 'Daily',
      RecurringFrequency.weekly => 'Weekly',
      RecurringFrequency.biWeekly => 'Bi-weekly',
      RecurringFrequency.monthly => 'Monthly',
      RecurringFrequency.quarterly => 'Quarterly',
      RecurringFrequency.yearly => 'Yearly',
      RecurringFrequency.custom => 'Custom',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

enum EndCondition { never, afterNTimes, onDate }

final _formCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dao = ref.watch(categoryDaoProvider);
  return dao.getAll();
});
