import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nomnom/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NomNomApp(),
      ),
    );

    // Just verify app pumps without crashing
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
