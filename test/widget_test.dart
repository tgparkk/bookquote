import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookquote/main.dart';

void main() {
  testWidgets('App boots and shows 책귀 in the AppBar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BookquoteApp()));

    expect(find.widgetWithText(AppBar, '책귀'), findsOneWidget);
    expect(find.text('Stage 1 setup complete'), findsOneWidget);
  });
}
