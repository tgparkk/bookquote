// PR18-C — 친구 프로필 화면 위젯 테스트.
//
// 헤더·세그먼트·잠긴 서재·닉네임 게이트 분기를 provider override + Mock repo로 검증.
// 실제 SupabaseClient 생성 X (`extends Mock implements` 패턴 — reading_dates_row_test 참조).

import 'package:bookquote/features/book/data/book_repository.dart';
import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/follow/state/follow_providers.dart';
import 'package:bookquote/features/profile/domain/profile.dart';
import 'package:bookquote/features/profile/presentation/friend_profile_screen.dart';
import 'package:bookquote/features/profile/state/friend_providers.dart';
import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

const _userId = 'friend-uid';

Profile _profile({
  String? name = '지윤',
  bool isPublic = true,
  String? avatar,
}) =>
    Profile(
      id: _userId,
      displayName: name,
      avatarUrl: avatar,
      publicHandle: null,
      isLibraryPublic: isPublic,
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Profile? profile,
    List<Book> books = const [],
    List<QuoteWithBook> quotes = const [],
    bool isFollowing = false,
    int followers = 0,
    int following = 0,
    BookRepository? bookRepo,
    QuoteRepository? quoteRepo,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendProfileProvider(_userId).overrideWith((ref) async => profile),
          friendBooksProvider(_userId).overrideWith((ref) async => books),
          isFollowingProvider(_userId).overrideWith((ref) async => isFollowing),
          friendFollowCountsProvider(_userId).overrideWith(
            (ref) async => (followers: followers, following: following),
          ),
          if (bookRepo != null) bookRepositoryProvider.overrideWithValue(bookRepo),
          if (quoteRepo != null)
            quoteRepositoryProvider.overrideWithValue(quoteRepo),
          if (quoteRepo == null)
            quoteRepositoryProvider.overrideWithValue(_StubQuoteRepo(quotes)),
        ],
        child: const MaterialApp(
          home: FriendProfileScreen(userId: _userId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('프로필 null → "사용자를 찾을 수 없어요" 빈상태 + [홈으로]',
      (tester) async {
    await pump(tester, profile: null);

    expect(find.text('사용자를 찾을 수 없어요'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '홈으로'), findsOneWidget);
  });

  testWidgets('display_name이 이메일 local-part 패턴(.포함) → 닉네임 게이트 풀스크린',
      (tester) async {
    await pump(tester, profile: _profile(name: 'john.doe'));

    expect(find.text('먼저 내 닉네임을 설정해주세요'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '내 정보로 이동'), findsOneWidget);
    // 세그먼트는 노출 X
    expect(find.text('책'), findsNothing);
    expect(find.text('인용구'), findsNothing);
  });

  testWidgets('display_name 빈값/null → 닉네임 게이트', (tester) async {
    await pump(tester, profile: _profile(name: ''));
    expect(find.text('먼저 내 닉네임을 설정해주세요'), findsOneWidget);
  });

  testWidgets('비공개 프로필 — 잠긴 서재 빈상태 + 팔로우 전 카피', (tester) async {
    await pump(tester, profile: _profile(isPublic: false));

    expect(find.text('이 서재는 비공개예요'), findsOneWidget);
    expect(find.text('공개 설정을 켜면 보여요.'), findsOneWidget);
    // 헤더 + 팔로우 버튼은 노출
    expect(find.widgetWithText(FilledButton, '팔로우'), findsOneWidget);
    // 세그먼트는 노출 X
    expect(find.byType(SegmentedButton<int>), findsNothing);
  });

  testWidgets('비공개 프로필 + 팔로잉 중 → 안내 카피 분기', (tester) async {
    await pump(
      tester,
      profile: _profile(isPublic: false),
      isFollowing: true,
    );

    expect(find.text('이 서재는 비공개예요'), findsOneWidget);
    expect(find.text('팔로우 중이에요. 서재가 공개되면 여기서 볼 수 있어요.'), findsOneWidget);
    // 팔로우 중이면 [팔로잉] OutlinedButton
    expect(find.widgetWithText(OutlinedButton, '팔로잉'), findsOneWidget);
  });

  testWidgets('공개 프로필 + 책 0권 → 세그먼트 + 빈상태 "아직 공개한 책이 없어요"',
      (tester) async {
    await pump(tester, profile: _profile());

    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.text('아직 공개한 책이 없어요'), findsOneWidget);
  });

  testWidgets('공개 프로필 + 책 1권 → 책 row 노출, 인용구 탭 전환 시 빈상태',
      (tester) async {
    const book = Book(
      id: 'b1',
      isbn13: '9791191056556',
      title: '미드나잇 라이브러리',
      author: '매트 헤이그',
    );
    await pump(tester, profile: _profile(), books: const [book]);

    expect(find.text('미드나잇 라이브러리'), findsOneWidget);
    expect(find.text('매트 헤이그'), findsOneWidget);

    // 인용구 탭 전환
    await tester.tap(find.text('인용구'));
    await tester.pumpAndSettle();
    expect(find.text('공개된 인용구가 없어요'), findsOneWidget);
  });

  testWidgets('헤더 카운트 노출 — "팔로워 N" / "팔로잉 N"', (tester) async {
    await pump(
      tester,
      profile: _profile(),
      followers: 12,
      following: 5,
    );

    expect(find.text('팔로워 12'), findsOneWidget);
    expect(find.text('팔로잉 5'), findsOneWidget);
  });
}

// QuoteRepository를 Mock하지만 친구 화면이 호출하는 메서드는 1개뿐 —
// `listFriendQuotesWithBook`. 그것만 stub.
class _StubQuoteRepo extends Mock implements QuoteRepository {
  _StubQuoteRepo(this._items);
  final List<QuoteWithBook> _items;

  @override
  Future<List<QuoteWithBook>> listFriendQuotesWithBook(
    String userId, {
    QuoteCursor? after,
    int limit = 15,
  }) async {
    return _items;
  }
}

