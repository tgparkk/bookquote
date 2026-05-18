// FirstLockDialog / UnlockDialog 입력 검증·취소 동작 테스트 (PR16-C-1).
//
// 성공 경로(createEnvelope + insert + cache) 검증은 통합 테스트 영역 — 여기선
// 입력 검증과 취소만 본다(provider 호출 없이 early return하는 케이스).

import 'package:bookquote/features/crypto/domain/envelope.dart';
import 'package:bookquote/features/crypto/presentation/lock_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

Future<bool?> _openFirstLock(WidgetTester tester) async {
  late bool? result;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const FirstLockDialog(),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  result = null;
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

Future<bool?> _openUnlock(WidgetTester tester) async {
  late bool? result;
  final fakeEnvelope = CryptoEnvelope(
    wrappedKey: Uint8List(48),
    wrapNonce: Uint8List(12),
    kdfSalt: Uint8List(16),
    kdfIters: 600000,
    kdfVersion: 1,
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => UnlockDialog(envelope: fakeEnvelope),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  result = null;
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('FirstLockDialog', () {
    testWidgets('6자 미만 비밀번호 차단', (tester) async {
      await _openFirstLock(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'abc');
      await tester.enterText(fields.at(1), 'abc');
      await tester.tap(find.text('잠금 설정'));
      await tester.pump();
      expect(find.text('비밀번호는 6자 이상이어야 해요.'), findsOneWidget);
      // 다이얼로그가 닫히지 않았는지 — pop 호출 안 됨
      expect(find.byType(FirstLockDialog), findsOneWidget);
    });

    testWidgets('두 비밀번호 불일치 차단', (tester) async {
      await _openFirstLock(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'longenough');
      await tester.enterText(fields.at(1), 'different!');
      await tester.tap(find.text('잠금 설정'));
      await tester.pump();
      expect(find.text('두 비밀번호가 달라요.'), findsOneWidget);
      expect(find.byType(FirstLockDialog), findsOneWidget);
    });

    testWidgets('취소 → pop(false)', (tester) async {
      // _openFirstLock은 반환값을 캡처 못 함 (Builder closure 안) — 다이얼로그
      // 사라짐 여부로 대체 검증.
      await _openFirstLock(tester);
      expect(find.byType(FirstLockDialog), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(FirstLockDialog), findsNothing);
    });

    testWidgets('한국어 비밀번호 길이도 runes 기준 6자', (tester) async {
      await _openFirstLock(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '책귀잠금');  // 4자 (runes)
      await tester.enterText(fields.at(1), '책귀잠금');
      await tester.tap(find.text('잠금 설정'));
      await tester.pump();
      expect(find.text('비밀번호는 6자 이상이어야 해요.'), findsOneWidget);
    });
  });

  group('UnlockDialog', () {
    testWidgets('빈 비밀번호 차단', (tester) async {
      await _openUnlock(tester);
      await tester.tap(find.text('잠금 해제'));
      await tester.pump();
      expect(find.text('비밀번호를 입력해주세요.'), findsOneWidget);
      expect(find.byType(UnlockDialog), findsOneWidget);
    });

    testWidgets('취소 → pop(false)', (tester) async {
      await _openUnlock(tester);
      expect(find.byType(UnlockDialog), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(UnlockDialog), findsNothing);
    });
  });

  group('showPrivateShareWarningDialog (PR16-C-2)', () {
    Future<void> openWarning(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showPrivateShareWarningDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('경고 제목·평문 박힘 카피·두 버튼 노출', (tester) async {
      await openWarning(tester);
      expect(find.text('잠금 인용구 공유'), findsOneWidget);
      expect(
        find.textContaining('카드 이미지에는 인용구가 평문으로'),
        findsOneWidget,
      );
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('그래도 공유'), findsOneWidget);
    });

    testWidgets('[취소] 탭 → 다이얼로그 닫힘', (tester) async {
      await openWarning(tester);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('잠금 인용구 공유'), findsNothing);
    });

    testWidgets('[그래도 공유] 탭 → 다이얼로그 닫힘', (tester) async {
      await openWarning(tester);
      await tester.tap(find.text('그래도 공유'));
      await tester.pumpAndSettle();
      expect(find.text('잠금 인용구 공유'), findsNothing);
    });
  });
}
