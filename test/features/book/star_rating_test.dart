import 'package:bookquote/features/book/presentation/widgets/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('읽기 전용 — rating 3이면 채워진 별 3개 + 빈 별 2개, IconButton 아님', (tester) async {
    await tester.pumpWidget(_wrap(const StarRating(rating: 3)));
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(2));
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('rating null이면 빈 별 5개', (tester) async {
    await tester.pumpWidget(_wrap(const StarRating(rating: null)));
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('인터랙티브 — 4번째 별 탭하면 onRated(4)', (tester) async {
    int? got = -1;
    await tester.pumpWidget(
      _wrap(StarRating(rating: 2, onRated: (v) => got = v)),
    );
    expect(find.byType(IconButton), findsNWidgets(5));
    await tester.tap(find.byType(IconButton).at(3));
    expect(got, 4);
  });

  testWidgets('현재 별점 별을 다시 탭하면 onRated(null) — 별점 지우기', (tester) async {
    int? got = -1;
    await tester.pumpWidget(
      _wrap(StarRating(rating: 3, onRated: (v) => got = v)),
    );
    await tester.tap(find.byType(IconButton).at(2)); // 3번째 = 현재 별점
    expect(got, isNull);
  });
}
