part of 'onboarding_screen.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    required this.logoController,
    required this.onGetStarted,
    super.key,
  });

  final AnimationController logoController;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated logo placeholder - scale animation
          ScaleTransition(
            scale: CurvedAnimation(
              parent: logoController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Welcome to Xpense',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Track your expenses effortlessly.\n'
            'Set budgets, get insights, and stay in control.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
