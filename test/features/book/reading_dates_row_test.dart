// PR17-B: ReadingDatesRow 위젯 테스트.

import 'package:bookquote/features/book/data/book_repository.dart';
import 'package:bookquote/features/book/domain/reading_dates.dart';
import 'package:bookquote/features/book/presentation/widgets/reading_dates_row.dart';
import 'package:bookquote/features/book/state/book_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  Future<_FakeRepo> pump(
    WidgetTester tester, {
    required ReadingDates dates,
    _FakeRepo? repo,
  }) async {
    final fake = repo ?? _FakeRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingDatesProvider('b1').overrideWith((ref) async => dates),
          bookRepositoryProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ReadingDatesRow(bookId: 'b1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('데이터 없음 — 두 행 모두 [오늘][어제][직접] 칩 노출', (tester) async {
    await pump(tester, dates: const ReadingDates());

    expect(find.text('읽기 시작'), findsOneWidget);
    expect(find.text('다 읽음'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '오늘'), findsNWidgets(2));
    expect(find.widgetWithText(OutlinedButton, '어제'), findsNWidgets(2));
    expect(find.widgetWithText(OutlinedButton, '직접'), findsNWidgets(2));
    expect(find.widgetWithText(TextButton, '지우기'), findsNothing);
  });

  testWidgets('시작일만 있음 — 시작 〔날짜〕 칩 + [지우기], 다 읽음은 입력 칩', (tester) async {
    await pump(
      tester,
      dates: ReadingDates(startedAt: DateTime(2026, 5, 12)),
    );

    expect(find.text('5월 12일'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '지우기'), findsOneWidget);
    // 다 읽음 행은 여전히 입력 칩
    expect(find.widgetWithText(OutlinedButton, '오늘'), findsOneWidget);
  });

  testWidgets('둘 다 있음 — 둘 다 〔날짜〕 칩 + [지우기]', (tester) async {
    await pump(
      tester,
      dates: ReadingDates(
        startedAt: DateTime(2026, 5, 10),
        finishedAt: DateTime(2026, 5, 17),
      ),
    );

    expect(find.text('5월 10일'), findsOneWidget);
    expect(find.text('5월 17일'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '지우기'), findsNWidgets(2));
    expect(find.widgetWithText(OutlinedButton, '오늘'), findsNothing);
  });

  testWidgets(
    'started 없이 finished [오늘] 탭 → setReadingDate 2회(finished+started) + SnackBar',
    (tester) async {
      final fake = await pump(tester, dates: const ReadingDates());

      // 두 번째 [오늘] = 다 읽음 행
      await tester.tap(find.widgetWithText(OutlinedButton, '오늘').at(1));
      await tester.pumpAndSettle();

      expect(fake.calls.length, 2);
      expect(
        fake.calls.where((c) => c.kind == ReadingDateKind.finished).length,
        1,
      );
      expect(
        fake.calls.where((c) => c.kind == ReadingDateKind.started).length,
        1,
      );
      expect(find.text('함께 시작일도 오늘로 저장했어요'), findsOneWidget);
    },
  );

  testWidgets('started 있는 상태에서 finished [오늘] 탭 → setReadingDate 1회(finished만, Toast 없음)',
      (tester) async {
    final fake = await pump(
      tester,
      dates: ReadingDates(startedAt: DateTime(2026, 5, 10)),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '오늘'));
    await tester.pumpAndSettle();

    expect(fake.calls.length, 1);
    expect(fake.calls.first.kind, ReadingDateKind.finished);
    expect(find.text('함께 시작일도 오늘로 저장했어요'), findsNothing);
  });

  testWidgets('[지우기] 탭 → setReadingDate(kind, null)', (tester) async {
    final fake = await pump(
      tester,
      dates: ReadingDates(startedAt: DateTime(2026, 5, 12)),
    );

    await tester.tap(find.widgetWithText(TextButton, '지우기'));
    await tester.pumpAndSettle();

    expect(fake.calls.length, 1);
    expect(fake.calls.first.kind, ReadingDateKind.started);
    expect(fake.calls.first.date, isNull);
  });
}

// `extends Mock implements BookRepository` 패턴 — 실제 SupabaseClient 생성 X
// (GoTrueClient의 periodic auto-refresh timer가 dispose 안 돼 테스트가 fail).
class _FakeRepo extends Mock implements BookRepository {
  final List<({ReadingDateKind kind, DateTime? date})> calls = [];

  @override
  Future<void> setReadingDate({
    required String bookId,
    required ReadingDateKind kind,
    DateTime? date,
  }) async {
    calls.add((kind: kind, date: date));
  }
}
