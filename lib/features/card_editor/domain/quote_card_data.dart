import 'package:flutter/foundation.dart';

/// 카드 한 장을 그리는 데 필요한 도메인 데이터.
/// quote_repository에서 가져온 quote + book join 결과를 이 위젯-friendly 묶음으로 변환해 사용한다.
@immutable
class QuoteCardData {
  const QuoteCardData({
    required this.quoteText,
    this.bookId,
    this.bookIsbn13,
    this.bookTitle,
    this.bookAuthor,
    this.bookPublisher,
    this.coverUrl,
    this.quotePage,
    this.isPrivate = false,
  });

  final String quoteText;
  /// PR11에서 추가 — `cards.book_id` INSERT용. book이 join되지 않으면 null.
  final String? bookId;
  /// V1.0 — 공유 시 교보문고 구매 링크 생성용 ISBN13. book이 join되지 않으면 null.
  final String? bookIsbn13;
  final String? bookTitle;
  final String? bookAuthor;
  final String? bookPublisher;
  final String? coverUrl;

  /// PR12 (2026-05-28): 이 인용구의 책 페이지 번호(사용자 입력). 공유 텍스트에
  /// `p.42` 형태로 출처를 명시한다. 카드 이미지엔 이미 박혀 있을 수 있으나
  /// 텍스트 공유에선 누락돼 받는 쪽이 출처 페이지를 모르던 문제 해소.
  final int? quotePage;

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
