import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/budgets/presentation/providers/budget_provider.dart';
import 'package:xpense/features/expenses/presentation/widgets/category_grid.dart';
import 'package:xpense/features/expenses/presentation/widgets/custom_keypad.dart';
import 'package:xpense/features/expenses/presentation/widgets/success_overlay.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({this.expenseToEdit, super.key});

  final Expense? expenseToEdit;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  late String _amountText;
  late String? _selectedCategoryId;
  late String _note;
  late String _merchant;
  late String _paymentMethod;
  bool _showSuccess = false;
  bool _saving = false;

  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _bounceScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.1), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.1, end: 1), weight: 50),
  ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

  static const _maxDigits = 8;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;
    if (expense != null) {
      _amountText = (expense.amountCents / 100).toStringAsFixed(2);
      _selectedCategoryId = expense.categoryId;
      _note = expense.note ?? '';
      _merchant = expense.merchant ?? '';
      _paymentMethod = expense.paymentMethod ?? '';
    } else {
      _amountText = '';
      _selectedCategoryId = null;
      _note = '';
      _merchant = '';
      _paymentMethod = '';
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_amountText.length >= _maxDigits) return;
    setState(() {
      _amountText += digit;
    });
    unawaited(_bounceController.forward(from: 0));
  }

  void _onDecimal() {
    if (!_amountText.contains('.')) {
      setState(() {
        _amountText = _amountText.isEmpty ? '0.' : '$_amountText.';
      });
      unawaited(_bounceController.forward(from: 0));
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

  Future<void> _onSave({bool addAnother = false}) async {
    final cents = _amountCents;
    if (cents == null || cents <= 0) {
      unawaited(HapticService.error());
      return;
    }
    if (_selectedCategoryId == null) {
      unawaited(HapticService.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a category')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final input = ExpenseInput(
      amountCents: cents,
      categoryId: _selectedCategoryId!,
      date: _isEditing ? widget.expenseToEdit!.date : DateTime.now(),
      note: _note.isNotEmpty ? _note : null,
      merchant: _merchant.isNotEmpty ? _merchant : null,
      paymentMethod: _paymentMethod.isNotEmpty ? _paymentMethod : null,
    );

    try {
      final dao = ref.read(expenseDaoProvider);
      if (_isEditing) {
        await dao.updateExpense(widget.expenseToEdit!.id, input);
      } else {
        await dao.create(input);
      }

      await _checkBudgetThresholds(cents);

      unawaited(HapticService.success());
      setState(() {
        _showSuccess = true;
        _saving = false;
      });

      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (_isEditing || !addAnother) {
        if (mounted) context.pop();
      } else {
        setState(() {
          _amountText = '';
          _selectedCategoryId = null;
          _note = '';
          _merchant = '';
          _paymentMethod = '';
          _showSuccess = false;
        });
      }
    } catch (e) {
      setState(() => _saving = false);
      unawaited(HapticService.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _showOptionalFields() async {
    final result = await showModalBottomSheet<_OptionalFieldsResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OptionalFieldsSheet(
        note: _note,
        merchant: _merchant,
        paymentMethod: _paymentMethod,
      ),
    );
    if (result != null) {
      setState(() {
        _note = result.note;
        _merchant = result.merchant;
        _paymentMethod = result.paymentMethod;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoriesAsync = ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: _saving ? null : () => _onSave(addAnother: true),
              child: const Text('Add another'),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Amount display
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ScaleTransition(
                    scale: _bounceScale,
                    child: Text(
                      '\$$_displayAmount',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                // Budget status for selected category
                if (_selectedCategoryId != null)
                  _BudgetStatusChip(categoryId: _selectedCategoryId!),

                // Category selection
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: categoriesAsync.when(
                      data: (categories) => SingleChildScrollView(
                        child: CategoryGrid(
                          categories: categories,
                          selectedId: _selectedCategoryId,
                          onSelect: (cat) {
                            setState(() => _selectedCategoryId = cat.id);
                          },
                        ),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error: $e'),
                      ),
                    ),
                  ),
                ),

                // Optional fields toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton.icon(
                    onPressed: _showOptionalFields,
                    icon: const Icon(Icons.edit_note),
                    label: Text(
                      _hasOptionalFields
                          ? 'Note, merchant, payment method'
                          : 'Add details (optional)',
                    ),
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
          ),

          if (_showSuccess) const SuccessOverlay(),
        ],
      ),
    );
  }

  bool get _hasOptionalFields =>
      _note.isNotEmpty || _merchant.isNotEmpty || _paymentMethod.isNotEmpty;

  Future<void> _checkBudgetThresholds(int cents) async {
    if (_selectedCategoryId == null) return;

    final container = ProviderContainer();
    final budget = await container.read(
      categoryBudgetProvider(_selectedCategoryId!).future,
    );
    if (budget == null) {
      container.dispose();
      return;
    }

    final remaining = await container.read(
      budgetRemainingProvider(budget.id).future,
    );
    container.dispose();

    final afterSpend = remaining - cents;
    final total = budget.amountCents;
    if (total <= 0) return;

    final pctBefore = (remaining / total).clamp(0.0, 1.0);
    final pctAfter = (afterSpend / total).clamp(0.0, 1.0);

    if (pctBefore >= 0.8 && pctAfter < 0.8) {
      // Just dropped below 80% — no haptic needed
    } else if (pctBefore > 1.0 && pctAfter <= 1.0) {
      // Just came back under budget — no haptic needed
    } else if (pctBefore < 0.8 && pctAfter >= 0.8 && pctAfter < 1.0) {
      // Crossed 80% threshold
      await HapticService.warning();
    } else if (pctBefore < 1.0 && pctAfter >= 1.0) {
      // Crossed 100% threshold — over budget
      await HapticService.doubleWarning();
    }
  }
}

/// Shows budget remaining for the selected category.
class _BudgetStatusChip extends ConsumerWidget {
  const _BudgetStatusChip({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(categoryBudgetProvider(categoryId));

    return budgetAsync.when(
      data: (budget) {
        if (budget == null) return const SizedBox.shrink();
        return _BudgetRemainingText(budgetId: budget.id, total: budget.amountCents);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BudgetRemainingText extends ConsumerWidget {
  const _BudgetRemainingText({
    required this.budgetId,
    required this.total,
  });

  final String budgetId;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAsync = ref.watch(budgetRemainingProvider(budgetId));

    return remainingAsync.when(
      data: (remaining) {
        final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
        final pct = total > 0 ? (1 - (remaining / total)).clamp(0.0, 1.0) : 0.0;
        final color = pct >= 1.0
            ? Colors.red
            : pct >= 0.8
                ? Colors.orange
                : Colors.green;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Chip(
            avatar: Icon(
              Icons.account_balance_wallet,
              size: 18,
              color: color,
            ),
            label: Text(
              remaining >= 0
                  ? '${currency.format(remaining / 100)} left'
                  : '${currency.format(remaining.abs() / 100)} over',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            backgroundColor: color.withValues(alpha: 0.1),
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

final _categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dao = ref.watch(categoryDaoProvider);
  return dao.getAll();
});

// ---------------------------------------------------------------------------
// Optional fields bottom sheet
// ---------------------------------------------------------------------------

class _OptionalFieldsResult {
  const _OptionalFieldsResult({
    required this.note,
    required this.merchant,
    required this.paymentMethod,
  });

  final String note;
  final String merchant;
  final String paymentMethod;
}

class _OptionalFieldsSheet extends StatefulWidget {
  const _OptionalFieldsSheet({
    required this.note,
    required this.merchant,
    required this.paymentMethod,
  });

  final String note;
  final String merchant;
  final String paymentMethod;

  @override
  State<_OptionalFieldsSheet> createState() => _OptionalFieldsSheetState();
}

class _OptionalFieldsSheetState extends State<_OptionalFieldsSheet> {
  late final _noteController = TextEditingController(text: widget.note);
  late final _merchantController = TextEditingController(text: widget.merchant);
  late final _paymentController =
      TextEditingController(text: widget.paymentMethod);

  @override
  void dispose() {
    _noteController.dispose();
    _merchantController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottom + 16,
      ),
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
            'Expense Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'e.g., Coffee with Sarah',
              prefixIcon: Icon(Icons.notes),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: 'Merchant',
              hintText: 'e.g., Starbucks',
              prefixIcon: Icon(Icons.store),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paymentController,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              hintText: 'e.g., Credit Card, Cash',
              prefixIcon: Icon(Icons.payment),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                _OptionalFieldsResult(
                  note: _noteController.text,
                  merchant: _merchantController.text,
                  paymentMethod: _paymentController.text,
                ),
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
