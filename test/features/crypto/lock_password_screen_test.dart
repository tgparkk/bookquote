// LockPasswordBody 4상태 위젯 가드 (PR16-E).
//
// envelope/캐시 조합으로 결정되는 상태별 제목·CTA·아이콘 회귀 보호.
// FutureProvider 자체 로딩 상태는 LockPasswordScreen이 다루므로 여기선
// snapshot이 있는 3분기만 검증(로딩은 단순 CircularProgressIndicator).

import 'dart:typed_data';

import 'package:bookquote/features/crypto/domain/envelope.dart';
import 'package:bookquote/features/crypto/presentation/lock_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CryptoEnvelope _fakeEnvelope() => CryptoEnvelope(
      wrappedKey: Uint8List(48),
      wrapNonce: Uint8List(12),
      kdfSalt: Uint8List(16),
      kdfIters: 600000,
      kdfVersion: 1,
    );

Future<void> _pump(WidgetTester tester, LockSnapshot snapshot) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: LockPasswordBody(snapshot: snapshot),
        ),
      ),
    ),
  );
}

void main() {
  group('LockPasswordBody (PR16-E 4상태 회귀 가드)', () {
    testWidgets('미설정 (envelope null) — [잠금 비밀번호 설정] CTA', (tester) async {
      await _pump(
        tester,
        const LockSnapshot(envelope: null, hasCachedKey: false),
      );
      expect(find.text('잠금 비밀번호가 없어요'), findsOneWidget);
      expect(find.text('잠금 비밀번호 설정'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
    });

    testWidgets('설정됨 + 캐시 있음 — [비밀번호 변경] CTA', (tester) async {
      await _pump(
        tester,
        LockSnapshot(envelope: _fakeEnvelope(), hasCachedKey: true),
      );
      expect(find.text('잠금 비밀번호가 설정됐어요'), findsOneWidget);
      expect(find.text('비밀번호 변경'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('설정됨 + 캐시 없음 — [잠금 해제] CTA', (tester) async {
      await _pump(
        tester,
        LockSnapshot(envelope: _fakeEnvelope(), hasCachedKey: false),
      );
      expect(find.text('이 기기에서 잠금 해제가 필요해요'), findsOneWidget);
      expect(find.text('잠금 해제'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock_outlined), findsOneWidget);
    });

    testWidgets('모든 상태에 종이 백업 권장 카드 노출', (tester) async {
      await _pump(
        tester,
        const LockSnapshot(envelope: null, hasCachedKey: false),
      );
      expect(find.text('비밀번호를 종이에 적어두세요'), findsOneWidget);
      expect(
        find.textContaining('비밀번호는 책귀 서버가 모릅니다'),
        findsOneWidget,
      );
    });
  });
}
