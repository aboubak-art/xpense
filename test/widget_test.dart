import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xpense/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: XpenseApp()));
    await tester.pumpAndSettle();

    expect(find.text('Xpense'), findsOneWidget);
    expect(find.text('Welcome to Xpense'), findsOneWidget);
    expect(find.text('Track your expenses effortlessly'), findsOneWidget);
  });

  testWidgets('App uses MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: XpenseApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
