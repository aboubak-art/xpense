part of 'onboarding_screen.dart';

class CurrencyPage extends StatelessWidget {
  const CurrencyPage({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.onContinue,
    super.key,
  });

  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Currency',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred currency for tracking expenses.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: Currencies.all.length,
              itemBuilder: (context, index) {
                final currency = Currencies.all[index];
                final isSelected = currency.code == selectedCurrency;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      currency.symbol,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Text(currency.name),
                  subtitle: Text(currency.code),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  onTap: () => onCurrencySelected(currency.code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
