// 인용구 삭제 + [되돌리기] SnackBar — 서버 삭제 확정 회귀 테스트.
//
// Flutter 3.41+는 action 있는 SnackBar의 persist 기본값이 true라 duration이
// 무시되고 영원히 떠 있었다 → closed가 오지 않아 서버 삭제가 미확정. 또 그 사이
// 뷰가 unmount되면(세그먼트 전환) `mounted` 가드로 삭제가 아예 실행되지 않았다.
// (2026-10-10 에뮬레이터 점검에서 앱 재시작 후에도 남은 삭제 스낵바로 발견)

import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/presentation/quote_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final QuoteWithBook _entry = (
  quote: Quote(
    id: 'q1',
    userId: 'u1',
    text: '삭제될 인용구',
    moods: const <QuoteMood>[],
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  ),
  book: null,
);

class _FakeRepo implements QuoteRepository {
  final deleted = <String>[];

  @override
  Future<List<MoodHubSnapshot>> listMoodHubSnapshots() async => const [];

  @override
  Future<MoodCounts> getMoodCounts() async =>
      (total: 1, byMood: const <QuoteMood, int>{});

  @override
  Future<List<QuoteWithBook>> listMyQuotesWithBook({
    String? bookId,
    Set<QuoteMood>? moods,
    QuoteCursor? after,
    int limit = 15,
  }) async =>
      after == null && !deleted.contains('q1') ? [_entry] : const [];

  @override
  Future<void> deleteQuote(String id) async => deleted.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepo repo;
  late ValueNotifier<bool> showList;

  Future<void> pumpAndDelete(WidgetTester tester) async {
    repo = _FakeRepo();
    showList = ValueNotifier(true);
    await tester.pumpWidget(ProviderScope(
      overrides: [quoteRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: showList,
            builder: (_, show, _) =>
                show ? const QuoteListView() : const SizedBox.shrink(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제될 인용구'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    // 등장 애니메이션 완료 → messenger rebuild 시 만료 타이머가 걸린다.
    await tester.pumpAndSettle();
    expect(find.text('인용구를 삭제했어요.'), findsOneWidget);
    expect(repo.deleted, isEmpty, reason: '되돌리기 기간 중엔 아직 미확정');
  }

  testWidgets('되돌리기 안 누르면 5초 뒤 스낵바가 닫히고 서버 삭제 확정', (tester) async {
    await pumpAndDelete(tester);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('인용구를 삭제했어요.'), findsNothing);
    expect(repo.deleted, ['q1']);
  });

  testWidgets('되돌리기 기간 중 뷰가 사라져도 삭제는 확정', (tester) async {
    await pumpAndDelete(tester);
    showList.value = false; // 서재 세그먼트 전환 등으로 unmount
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['q1']);
  });

  testWidgets('되돌리기 누르면 삭제 안 하고 목록 복구', (tester) async {
    await pumpAndDelete(tester);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(repo.deleted, isEmpty);
    expect(find.text('삭제될 인용구'), findsOneWidget);
  });
}
