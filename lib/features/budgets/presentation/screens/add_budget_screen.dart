import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/core/utils/color_utils.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/features/budgets/presentation/providers/budget_provider.dart';
import 'package:xpense/features/categories/presentation/providers/category_provider.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({this.budgetToEdit, super.key});

  final Budget? budgetToEdit;

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late BudgetPeriod _period;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _rolloverUnused;
  late int _alertThreshold;
  String? _categoryId;
  bool _saving = false;

  bool get _isEditing => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budgetToEdit;
    _nameController = TextEditingController(text: b?.name ?? '');
    _amountController = TextEditingController(
      text: b != null ? (b.amountCents / 100).toStringAsFixed(2) : '',
    );
    _period = b?.period ?? BudgetPeriod.monthly;
    _startDate = b?.startDate ?? DateTime.now();
    _endDate = b?.endDate;
    _rolloverUnused = b?.rolloverUnused ?? false;
    _alertThreshold = b?.alertThresholdPercent ?? 80;
    _categoryId = b?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (name.isEmpty || amount == null || amount <= 0) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid name and amount')),
        );
      }
      return;
    }

    if (_period == BudgetPeriod.custom && _endDate == null) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an end date for custom period')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final input = BudgetInput(
      name: name,
      amountCents: (amount * 100).round(),
      startDate: _startDate,
      period: _period,
      categoryId: _categoryId,
      endDate: _endDate,
      rolloverUnused: _rolloverUnused,
      alertThresholdPercent: _alertThreshold,
    );

    final notifier = ref.read(budgetFormNotifierProvider.notifier);

    if (_isEditing) {
      await notifier.update(widget.budgetToEdit!.id, input);
    } else {
      await notifier.create(input);
    }

    setState(() => _saving = false);

    final state = ref.read(budgetFormNotifierProvider);
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Budget' : 'New Budget'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Budget Name',
              hintText: 'e.g., Monthly Groceries',
              prefixIcon: Icon(Icons.label_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: '0.00',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 24),

          // Period
          Text(
            'Period',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<BudgetPeriod>(
            segments: const [
              ButtonSegment(
                value: BudgetPeriod.daily,
                label: Text('Daily'),
              ),
              ButtonSegment(
                value: BudgetPeriod.weekly,
                label: Text('Weekly'),
              ),
              ButtonSegment(
                value: BudgetPeriod.monthly,
                label: Text('Monthly'),
              ),
              ButtonSegment(
                value: BudgetPeriod.custom,
                label: Text('Custom'),
              ),
            ],
            selected: {_period},
            onSelectionChanged: (set) {
              HapticService.selectionClick();
              setState(() => _period = set.first);
            },
          ),
          const SizedBox(height: 16),

          // Start date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Start Date'),
            subtitle: Text(_formatDate(_startDate)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickStartDate,
          ),

          // End date (only for custom)
          if (_period == BudgetPeriod.custom)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('End Date'),
              subtitle: Text(
                _endDate != null ? _formatDate(_endDate!) : 'Select date',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickEndDate,
            ),

          const Divider(),

          // Category filter
          Text(
            'Applies To',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) {
              return DropdownButtonFormField<String?>(
                value: _categoryId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category),
                ),
                hint: const Text('All expenses'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All expenses'),
                  ),
                  ...categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: hexToColor(c.colorHex),
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  )),
                ],
                onChanged: (val) => setState(() => _categoryId = val),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load categories'),
          ),
          const SizedBox(height: 16),

          // Rollover
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rollover unused budget'),
            subtitle: const Text(
              'Carry over remaining amount to next period',
            ),
            value: _rolloverUnused,
            onChanged: (val) => setState(() => _rolloverUnused = val),
          ),

          // Alert threshold
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Alert Threshold'),
            subtitle: Text('Warn when spending reaches $_alertThreshold%'),
          ),
          Slider(
            value: _alertThreshold.toDouble(),
            min: 50,
            max: 100,
            divisions: 10,
            label: '$_alertThreshold%',
            onChanged: (val) {
              setState(() => _alertThreshold = val.round());
            },
          ),
          const SizedBox(height: 24),

          // Save button
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save Changes' : 'Create Budget'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

}
