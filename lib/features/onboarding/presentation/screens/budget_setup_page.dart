part of 'onboarding_screen.dart';

class BudgetSetupPage extends StatefulWidget {
  const BudgetSetupPage({
    required this.budgetCents,
    required this.currency,
    required this.onBudgetChanged,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  final int? budgetCents;
  final String currency;
  final ValueChanged<int?> onBudgetChanged;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  State<BudgetSetupPage> createState() => _BudgetSetupPageState();
}

class _BudgetSetupPageState extends State<BudgetSetupPage> {
  late final _controller = TextEditingController(
    text: widget.budgetCents != null
        ? (widget.budgetCents! / 100).toStringAsFixed(2)
        : '',
  );

  String get _symbol {
    try {
      return Currencies.all.firstWhere((c) => c.code == widget.currency).symbol;
    } catch (_) {
      return '\$';
    }
  }

  void _onChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      widget.onBudgetChanged((parsed * 100).round());
    } else {
      widget.onBudgetChanged(null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set a Monthly Budget',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps you stay on track. You can always change it later.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Text(
                  _symbol,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: _onChanged,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'per month',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip for now'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
