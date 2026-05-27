import 'package:bookquote/features/book/book_detail_screen.dart';
import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/book/state/book_providers.dart';
import 'package:bookquote/features/follow/state/follow_providers.dart';
import 'package:bookquote/features/profile/domain/profile.dart';
import 'package:bookquote/features/profile/state/friend_providers.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/state/quote_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _book = Book(
  id: 'b1',
  isbn13: '9791191056556',
  title: '미드나잇 라이브러리',
  author: '매트 헤이그',
  publisher: '인플루엔셜',
  pubDate: '2021',
  description: '미드나잇 라이브러리는 삶과 죽음 사이의 도서관 이야기.',
);

Quote _quote(String id, String text, {List<QuoteMood> moods = const []}) => Quote(
      id: id,
      userId: 'u1',
      bookId: 'b1',
      text: text,
      moods: moods,
      createdAt: DateTime(2026, 5, 12),
      updatedAt: DateTime(2026, 5, 12),
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? from,
    String? sender,
    Profile? senderProfile,
    Book? book = _book,
    List<Quote> quotes = const [],
    bool inLibrary = false,
    int friendsWithBookCount = 0,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookByIdProvider('b1').overrideWith((ref) => book),
          bookQuotesProvider('b1').overrideWith((ref) => quotes),
          isInLibraryProvider('b1').overrideWith((ref) => inLibrary),
          friendsWithBookCountProvider('b1')
              .overrideWith((ref) async => friendsWithBookCount),
          if (sender != null)
            friendProfileProvider(sender)
                .overrideWith((ref) async => senderProfile),
        ],
        child: MaterialApp(
          home: BookDetailScreen(bookId: 'b1', from: from, sender: sender),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('일반 진입 — 제목·저자·"이 책 인용구 추가" CTA, 안 담겼으면 [서재에 담기]', (tester) async {
    await pump(tester);

    expect(find.text('미드나잇 라이브러리'), findsOneWidget);
    expect(find.text('매트 헤이그'), findsOneWidget);
    // PR30-B 이후 ISBN은 헤더가 아닌 기본정보 그리드의 단일 셀에 표시.
    expect(find.text('9791191056556'), findsOneWidget);
    expect(find.text('ISBN 9791191056556'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, '이 책 인용구 추가'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '서재에 담기'), findsOneWidget);
    // 공유 배너는 일반 진입에선 없음
    expect(find.textContaining('누군가 이 책의 한 줄을 보냈어요'), findsNothing);
  });

  testWidgets('이미 서재에 있으면 [서재에 담기] 대신 "서재에 있음" 칩', (tester) async {
    await pump(tester, inLibrary: true);

    expect(find.text('서재에 있음'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '서재에 담기'), findsNothing);
  });

  testWidgets('deep link 진입(?from=share) — 공유 배너 + "내 서재에 담기" 1급 CTA', (tester) async {
    await pump(tester, from: 'share');

    expect(find.textContaining('누군가 이 책의 한 줄을 보냈어요'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '내 서재에 담기'), findsOneWidget);
  });

  testWidgets('이 책에서 모은 구절 — 개수 + 인용구 텍스트 표시', (tester) async {
    await pump(tester, quotes: [
      _quote('q1', '가장 깊은 밤에 가장 빛나는 별이 보인다.', moods: [QuoteMood.comfort]),
      _quote('q2', '후회는 인생에서 가장 무거운 짐.'),
    ]);

    expect(find.text('이 책에서 모은 구절'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // PR30-A 이후 첫 인용구는 hero 카드 + 리스트 양쪽에 노출됨(의도된 중복).
    expect(find.textContaining('가장 깊은 밤에'), findsNWidgets(2));
    expect(find.textContaining('후회는 인생'), findsOneWidget);
    expect(find.text('아직 이 책에서 모은 구절이 없어요.'), findsNothing);
  });

  testWidgets('인용구 0개면 "아직 이 책에서 모은 구절이 없어요"', (tester) async {
    await pump(tester);
    expect(find.text('아직 이 책에서 모은 구절이 없어요.'), findsOneWidget);
  });

  testWidgets('긴 설명이면 "더 보기" 토글 — 탭하면 "접기"로 바뀜', (tester) async {
    final longBook = Book(
      id: 'b1',
      isbn13: '9791191056556',
      title: '미드나잇 라이브러리',
      description: '미드나잇 라이브러리는 삶과 죽음 사이의 도서관 이야기. ' * 30,
    );
    await pump(tester, book: longBook);

    final more = find.text('더 보기');
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('접기'), findsOneWidget);
    expect(find.text('더 보기'), findsNothing);
  });

  testWidgets('책이 없으면 "이 책을 더 이상 볼 수 없어요" + 출구 버튼', (tester) async {
    await pump(tester, book: null);

    expect(find.text('이 책을 더 이상 볼 수 없어요'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '홈으로'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '내 서재'), findsOneWidget);
  });

  group('PR18-D → PR30-B — "친구 N명도 담음" inline chip', () {
    testWidgets('친구 0명 → chip 자체 숨김 (빈상태 회피)', (tester) async {
      await pump(tester);
      expect(find.textContaining('친구'), findsNothing);
    });

    testWidgets('친구 N≥1 → "친구 N명도 담음" chip이 인용구 섹션 헤더에 노출',
        (tester) async {
      await pump(tester, friendsWithBookCount: 3);
      expect(find.text('친구 3명도 담음'), findsOneWidget);
      // 옛 행 텍스트는 더 이상 존재하지 않음
      expect(find.text('이 책을 담은 친구 3명'), findsNothing);
    });
  });

  group('PR30-B — 기본정보 그리드 + 액션 행', () {
    testWidgets('InfoGrid — 페이지·출간·분류·ISBN 4셀, ISBN은 헤더가 아닌 그리드에서 표시',
        (tester) async {
      const book = Book(
        id: 'b1',
        isbn13: '9791191056556',
        title: '미드나잇 라이브러리',
        pubDate: '2021-03-15',
        categoryName: '소설',
        pageCount: 280,
      );
      await pump(tester, book: book);

      expect(find.text('기본 정보'), findsOneWidget);
      expect(find.text('쪽수'), findsOneWidget);
      expect(find.text('280쪽'), findsOneWidget);
      expect(find.text('출간'), findsOneWidget);
      expect(find.text('2021'), findsOneWidget);
      expect(find.text('분류'), findsOneWidget);
      expect(find.text('소설'), findsOneWidget);
      // ISBN은 그리드 안에만 있음(헤더 텍스트로 노출되지 않음)
      expect(find.text('ISBN'), findsOneWidget);
      expect(find.text('9791191056556'), findsOneWidget);
      expect(find.text('ISBN 9791191056556'), findsNothing);
    });

    testWidgets('InfoGrid — pageCount null → "입력하기 ▸" 강조 셀', (tester) async {
      const book = Book(
        id: 'b1',
        isbn13: '9791191056556',
        title: '미드나잇 라이브러리',
      );
      await pump(tester, book: book);

      expect(find.text('입력하기 ▸'), findsOneWidget);
      expect(find.textContaining('쪽'), findsOneWidget); // "쪽수" 라벨만, 값 아님
    });

    testWidgets('InfoGrid — 출간·분류 빈 값이면 "—"', (tester) async {
      const book = Book(
        id: 'b1',
        isbn13: '',
        title: '메타 없는 책',
      );
      await pump(tester, book: book);
      // 출간/분류/ISBN 셀 모두 "—"
      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('액션 행 — 일반 진입은 [인용구 추가]+[서재에 담기] 1줄 Row',
        (tester) async {
      await pump(tester);
      // 두 버튼은 1줄 Row에 같이 있음(렌더 트리에서 둘 다 존재)
      expect(find.widgetWithText(ElevatedButton, '이 책 인용구 추가'),
          findsOneWidget);
      expect(
          find.widgetWithText(OutlinedButton, '서재에 담기'), findsOneWidget);
    });

    testWidgets('액션 행 — fromShare 진입은 상단 큰 CTA + 인용구 버튼만(보조 서재 X)',
        (tester) async {
      await pump(tester, from: 'share');
      // 상단의 큰 "내 서재에 담기"
      expect(find.widgetWithText(ElevatedButton, '내 서재에 담기'),
          findsOneWidget);
      // 액션 행에는 보조 "서재에 담기" 없음
      expect(find.widgetWithText(OutlinedButton, '서재에 담기'), findsNothing);
      // 인용구 버튼은 그대로
      expect(find.widgetWithText(ElevatedButton, '이 책 인용구 추가'),
          findsOneWidget);
    });
  });

  group('PR30-A — 인용구 hero 카드 3-state', () {
    testWidgets('State 1: 내 인용구 있으면 hero 큰 따옴표 카드', (tester) async {
      await pump(tester, quotes: [
        _quote('q1', '가장 깊은 밤에 가장 빛나는 별이 보인다.'),
      ]);
      // hero(1) + 리스트(1) 양쪽 노출
      expect(find.textContaining('가장 깊은 밤에'), findsNWidgets(2));
      // description fallback도, empty CTA도 안 보임
      expect(find.text('출판사 소개'), findsNothing);
      expect(find.text('이 책의 첫 인용구를 남겨주세요'), findsNothing);
    });

    testWidgets(
        'State 1: 잠긴 인용구(text=null) 1개 → hero에서 건너뛰고 description fallback',
        (tester) async {
      final lockedQuote = Quote(
        id: 'q-locked',
        userId: 'u1',
        bookId: 'b1',
        text: null,
        isPrivate: true,
        cryptoVersion: 1,
        createdAt: DateTime(2026, 5, 12),
        updatedAt: DateTime(2026, 5, 12),
      );
      await pump(tester, quotes: [lockedQuote]);
      expect(find.text('출판사 소개'), findsOneWidget);
      expect(find.text('이 책의 첫 인용구를 남겨주세요'), findsNothing);
    });

    testWidgets('State 2: 인용구 없고 description 있으면 "출판사 소개" 미리보기',
        (tester) async {
      await pump(tester);
      expect(find.text('출판사 소개'), findsOneWidget);
      // hero(1) + 본문 설명(1) 양쪽 노출
      expect(find.textContaining('미드나잇 라이브러리는 삶과 죽음'),
          findsNWidgets(2));
      expect(find.text('이 책의 첫 인용구를 남겨주세요'), findsNothing);
    });

    testWidgets('State 3: 인용구·description 모두 없으면 "첫 인용구 남겨주세요" CTA',
        (tester) async {
      const emptyBook = Book(
        id: 'b1',
        isbn13: '9791191056556',
        title: '제목 없는 책',
      );
      await pump(tester, book: emptyBook);
      expect(find.text('이 책의 첫 인용구를 남겨주세요'), findsOneWidget);
      expect(find.text('출판사 소개'), findsNothing);
    });
  });

  group('PR30-A — 헤더 (큰 표지 + 중앙 별점)', () {
    testWidgets('큰 표지 BookCover 140×200, 미로그인이면 "내 별점" 블록 숨김',
        (tester) async {
      await pump(tester);
      // 미로그인 → 별점·읽기날짜 모두 안 보임
      expect(find.text('내 별점'), findsNothing);
      expect(find.text('읽기 시작'), findsNothing);
    });
  });

  group('PR20-C — sender 컨텍스트 (deep link)', () {
    const senderUid = 'friend-uid';
    const senderProfile = Profile(
      id: senderUid,
      displayName: '지윤',
      isLibraryPublic: true,
    );

    testWidgets('from=share + sender 공개 프로필 → 발신자 이름 + [이 사람 서재 보기] 버튼',
        (tester) async {
      await pump(
        tester,
        from: 'share',
        sender: senderUid,
        senderProfile: senderProfile,
      );
      expect(find.text('지윤님이 이 책의 한 줄을 보냈어요.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '이 사람 서재 보기'), findsOneWidget);
    });

    testWidgets('from=share + sender 비공개(null) → 익명 카피, 버튼 없음',
        (tester) async {
      await pump(
        tester,
        from: 'share',
        sender: senderUid,
        senderProfile: null,
      );
      expect(find.textContaining('누군가 이 책의 한 줄을 보냈어요'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '이 사람 서재 보기'), findsNothing);
    });

    testWidgets('from=share + sender 없음 → 익명 카피, 버튼 없음', (tester) async {
      await pump(tester, from: 'share');
      expect(find.textContaining('누군가 이 책의 한 줄을 보냈어요'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '이 사람 서재 보기'), findsNothing);
    });
  });
}
