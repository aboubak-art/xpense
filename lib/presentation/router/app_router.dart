import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:xpense/core/providers/onboarding_provider.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:xpense/features/home/presentation/screens/home_screen.dart';
import 'package:xpense/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:xpense/features/recurring/presentation/screens/recurring_expenses_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final onboardingComplete = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Don't redirect if already on onboarding
      if (state.matchedLocation == '/onboarding') {
        return null;
      }

      // Redirect to onboarding if not complete
      if (!onboardingComplete) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => AddExpenseScreen(
          expenseToEdit: state.extra as Expense?,
        ),
      ),
      GoRoute(
        path: '/recurring',
        builder: (context, state) => const RecurringExpensesScreen(),
      ),
    ],
  );
}
