// LoginScreen 위젯 테스트 (PR21 OAuth 전용).
//
// 매직링크 폼·_SentNotice·F1 회귀 가드는 V1에서 모두 제거됨 — 진입점이
// 구글·카카오 두 OAuth로 단순화. 여기선 *렌더 회귀*에 집중:
//   - 두 OAuth 버튼이 노출되는가
//   - env 키 미주입 환경에서 disabled + 안내 텍스트가 보이는가
// 실제 OAuth 호출은 SDK 채널에 의존하므로 위젯 테스트가 아닌 실기기 검증에서.

import 'package:bookquote/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('구글·카카오 OAuth 버튼이 노출된다', (tester) async {
    await pumpLogin(tester);

    expect(find.text('책귀에 오신 걸 환영합니다'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '구글로 시작'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '카카오로 시작'), findsOneWidget);
  });

  testWidgets('매직링크 잔존 UI가 보이지 않는다 (회귀 가드)', (tester) async {
    await pumpLogin(tester);

    expect(find.text('이메일로 시작'), findsNothing);
    expect(find.text('이메일을 보냈어요'), findsNothing);
    expect(find.text('이메일이 다른가요? 다시 입력'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('env 키 미주입 환경에서 두 버튼 모두 disabled + 안내 노출',
      (tester) async {
    // `flutter test` 기본 실행은 `--dart-define`이 비어 있어
    // `Env.isGoogleConfigured == false`, `Env.isKakaoConfigured == false`.
    await pumpLogin(tester);

    final googleBtn =
        tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '구글로 시작'));
    final kakaoBtn =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '카카오로 시작'));
    expect(googleBtn.onPressed, isNull);
    expect(kakaoBtn.onPressed, isNull);
    expect(
      find.textContaining('로그인 키가 설정되지 않았습니다'),
      findsOneWidget,
    );
  });
}
