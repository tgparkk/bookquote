import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookquote/main.dart';

void main() {
  testWidgets('Cold boot routes through splash to login', (tester) async {
    // Supabase가 초기화되지 않은 상태(테스트 환경)에서 부팅하면
    // splash가 즉시 /auth/login으로 이동해야 한다.
    await tester.pumpWidget(const ProviderScope(child: BookquoteApp()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '로그인'), findsOneWidget);
    expect(find.text('책귀에 오신 걸 환영합니다'), findsOneWidget);
  });
}
