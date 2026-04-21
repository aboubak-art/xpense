import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:xpense/core/providers/onboarding_provider.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/budgets/presentation/screens/add_budget_screen.dart';
import 'package:xpense/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:xpense/features/categories/presentation/screens/add_category_screen.dart';
import 'package:xpense/features/categories/presentation/screens/categories_screen.dart';
import 'package:xpense/features/categories/presentation/screens/category_detail_screen.dart';
import 'package:xpense/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:xpense/features/analytics/presentation/screens/analytics_screen.dart';
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
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/categories/add',
        builder: (context, state) => AddCategoryScreen(
          categoryToEdit: state.extra as Category?,
        ),
      ),
      GoRoute(
        path: '/categories/detail',
        builder: (context, state) => CategoryDetailScreen(
          category: state.extra as Category,
        ),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/budgets/add',
        builder: (context, state) => AddBudgetScreen(
          budgetToEdit: state.extra as Budget?,
        ),
      ),
    ],
  );
}
