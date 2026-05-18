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
    this.isPrivate = false,
  });

  final String quoteText;
  /// PR11에서 추가 — `cards.book_id` INSERT용. book이 join되지 않으면 null.
  final String? bookId;
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookPublisher;
  final String? coverUrl;

  /// PR16-C-2 — 잠금 인용구 여부. true면 공유 직전 평문 경고 모달 노출 +
  /// `quoteText`가 빈 문자열(키 없음)이면 카드 에디터/quick_share 잠금 안내 화면.
  final bool isPrivate;

  /// 코드포인트 기준 글자 수 — 폰트 크기 보간·T5 50자 게이트에 사용.
  /// 한글·기본 이모지 모두 1로 카운트(surrogate pair 보정).
  int get charCount => quoteText.runes.length;

  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// 잠금 + 본문 복호화 실패(키 없음/잘못된 키) 케이스. 카드 에디터·quick_share가
  /// 이 분기에서 _LockedView를 표시하고 편집·공유 진입을 막는다.
  bool get isLockedAndUnreadable => isPrivate && quoteText.isEmpty;
}
