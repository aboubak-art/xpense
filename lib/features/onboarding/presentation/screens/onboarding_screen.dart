import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/constants/currencies.dart';
import 'package:xpense/core/providers/onboarding_provider.dart';

part 'welcome_page.dart';
part 'currency_page.dart';
part 'budget_setup_page.dart';
part 'tutorial_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  final _totalPages = 4;

  late AnimationController _logoController;

  String _selectedCurrency = 'USD';
  int? _budgetAmountCents;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Auto-detect currency
    final locale = Platform.localeName;
    final detected = Currencies.detect(locale);
    if (detected != null) {
      _selectedCurrency = detected.code;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) {
      context.go('/');
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    if (page == 0) {
      _logoController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator and skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Skip button (except on last page)
                  if (!isLastPage)
                    TextButton(
                      onPressed: _skipPage,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  WelcomePage(
                    logoController: _logoController,
                    onGetStarted: _nextPage,
                  ),
                  CurrencyPage(
                    selectedCurrency: _selectedCurrency,
                    onCurrencySelected: (code) {
                      setState(() => _selectedCurrency = code);
                    },
                    onContinue: _nextPage,
                  ),
                  BudgetSetupPage(
                    budgetCents: _budgetAmountCents,
                    currency: _selectedCurrency,
                    onBudgetChanged: (cents) {
                      setState(() => _budgetAmountCents = cents);
                    },
                    onContinue: _nextPage,
                    onSkip: _nextPage,
                  ),
                  TutorialPage(
                    onComplete: _finishOnboarding,
                  ),
                ],
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(
                    isLastPage ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
