// 카드 공유 시트 — 4버튼 + 안내 카피 렌더 검증.
// V1은 4버튼 모두 share_plus OS 시트로 통합되므로 onTap을 실제 호출하지 않고
// 위젯 트리만 검증한다 — 플랫폼 채널 모킹은 V1.1.

import 'package:bookquote/features/card_editor/presentation/widgets/share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  testWidgets('showCardShareSheet — 4버튼 + 안내 카피 모두 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCardShareSheet(
                  context: context,
                  file: XFile('dummy.png'),
                  shareText: '인용구 본문',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('카카오톡 단톡방으로 보내기'), findsOneWidget);
    expect(find.text('인스타그램 스토리 (9:16)'), findsOneWidget);
    expect(find.text('이미지 저장'), findsOneWidget);
    expect(find.text('다른 앱으로 공유'), findsOneWidget);
    expect(find.text('저장 권한이 없어도 공유는 그대로 할 수 있어요.'), findsOneWidget);
    // bookId 없으면 링크가 없으니 붙여넣기 안내도 없다.
    expect(find.textContaining('앱 링크는 자동 복사'), findsNothing);
  });

  testWidgets('bookId 있으면 링크 자동 복사 안내 카피가 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCardShareSheet(
                  context: context,
                  file: XFile('dummy.png'),
                  shareText: '인용구 본문',
                  bookId: 'book-1',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('앱 링크는 자동 복사'), findsOneWidget);
  });

  group('buildBookPurchaseUrl (V1.0 — 책 구매 링크)', () {
    test('ISBN13 → 교보문고 검색 URL', () {
      expect(
        buildBookPurchaseUrl('9791191056556'),
        'https://search.kyobobook.co.kr/search?keyword=9791191056556',
      );
    });

    test('null·빈 ISBN → null (직접 입력 책 폴백)', () {
      expect(buildBookPurchaseUrl(null), isNull);
      expect(buildBookPurchaseUrl('   '), isNull);
    });
  });

  group('buildShareLandingLink (https 랜딩 — 미설치자 클릭 가능)', () {
    test('bookId → GitHub Pages 랜딩 URL (from=share 포함)', () {
      expect(
        buildShareLandingLink(bookId: 'abc-123'),
        'https://tgparkk.github.io/bookquote/b/?id=abc-123&from=share',
      );
    });

    test('sender uid는 링크에 포함되지 않는다 (공개 URL 노출 방지)', () {
      expect(buildShareLandingLink(bookId: 'abc'), isNot(contains('sender')));
    });

    test('bookId 없으면 null (이미지만 공유)', () {
      expect(buildShareLandingLink(bookId: null), isNull);
      expect(buildShareLandingLink(bookId: ''), isNull);
    });
  });

  group('buildShareMessage', () {
    test('랜딩 링크 + 구매 링크 모두 포함', () {
      final msg = buildShareMessage(
        link: 'https://tgparkk.github.io/bookquote/b/?id=1&from=share',
        purchaseUrl: 'https://search.kyobobook.co.kr/search?keyword=978',
      );
      expect(msg, contains('https://tgparkk.github.io/bookquote/b/?id=1'));
      expect(msg, contains('교보문고'));
      expect(msg, contains('https://search.kyobobook.co.kr/search?keyword=978'));
    });

    test('구매 링크만 — 랜딩 링크 없는 직접 입력 책', () {
      final msg = buildShareMessage(
        link: null,
        purchaseUrl: 'https://search.kyobobook.co.kr/search?keyword=978',
      );
      expect(msg, contains('교보문고'));
      expect(msg, isNot(contains('bookquote/b/')));
    });

    test('둘 다 없으면 null (이미지만 공유)', () {
      expect(buildShareMessage(link: null, purchaseUrl: null), isNull);
    });
  });
}
