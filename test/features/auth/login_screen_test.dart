// LoginScreen 위젯 테스트 — F1 매직링크 _SentNotice 탈출구 회귀 가드.
//
// _SentNotice 진입 후 [다시 입력] TextButton 탭 → _linkSent=false 토글 →
// Form 입력 화면으로 복귀하는 동선이 깨지면 신규 가입 시 이메일 오타 사용자가
// 앱 재시작 외 탈출구를 잃는다.

import 'package:bookquote/features/auth/auth_controller.dart';
import 'package:bookquote/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthController extends AuthController {
  @override
  Future<void> build() async {}

  @override
  Future<void> sendMagicLink({
    required String email,
    required String redirectTo,
  }) async {
    // 즉시 성공 — 실제 Supabase 호출 우회.
    state = const AsyncData(null);
  }
}

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('이메일 입력 → [이메일로 시작] → _SentNotice 진입', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, '이메일로 시작'));
    await tester.pump();

    expect(find.text('이메일을 보냈어요'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(find.text('이메일이 다른가요? 다시 입력'), findsOneWidget);
  });

  testWidgets('_SentNotice → [다시 입력] 탭 시 Form 입력 화면 복귀 (F1)', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField), 'typo@exmple.com');
    await tester.tap(find.widgetWithText(ElevatedButton, '이메일로 시작'));
    await tester.pump();

    expect(find.text('이메일을 보냈어요'), findsOneWidget);

    await tester.tap(find.text('이메일이 다른가요? 다시 입력'));
    await tester.pump();

    expect(find.text('이메일을 보냈어요'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, '이메일로 시작'), findsOneWidget);
    // 입력 필드는 그대로 남아 있어 사용자가 한 글자만 수정해도 됨.
    expect(find.text('typo@exmple.com'), findsOneWidget);
  });
}
