import 'package:flutter/foundation.dart';

/// 카드 한 장을 그리는 데 필요한 도메인 데이터.
/// quote_repository에서 가져온 quote + book join 결과를 이 위젯-friendly 묶음으로 변환해 사용한다.
@immutable
class QuoteCardData {
  const QuoteCardData({
    required this.quoteText,
    this.bookId,
    this.bookTitle,
    this.bookAuthor,
    this.bookPublisher,
    this.coverUrl,
  });

  final String quoteText;
  /// PR11에서 추가 — `cards.book_id` INSERT용. book이 join되지 않으면 null.
  final String? bookId;
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookPublisher;
  final String? coverUrl;

  /// 코드포인트 기준 글자 수 — 폰트 크기 보간·T5 50자 게이트에 사용.
  /// 한글·기본 이모지 모두 1로 카운트(surrogate pair 보정).
  int get charCount => quoteText.runes.length;

  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;
}
