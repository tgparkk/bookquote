// 책 후기 도메인 모델 (PR29).
// `public.book_reviews` row와 1:1. 인용구(Quote)와 별도 — 인용구는 책 문장 옮김,
// 후기는 본인 감상. 1책당 1개라 PK는 (user_id, book_id).

import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_review.freezed.dart';
part 'book_review.g.dart';

@freezed
abstract class BookReview with _$BookReview {
  const factory BookReview({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'book_id') required String bookId,
    required String text,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _BookReview;

  factory BookReview.fromJson(Map<String, dynamic> json) =>
      _$BookReviewFromJson(json);
}

/// 후기 본문 길이 제약 — DB CHECK와 동일(btrim 후 1~3000자).
class BookReviewLimits {
  static const int minLength = 1;
  static const int maxLength = 3000;

  /// 입력 검증. 통과하면 null, 위반이면 사용자에게 보여줄 메시지.
  static String? validate(String text) {
    final trimmed = text.trim();
    if (trimmed.length < minLength) return '후기를 1자 이상 입력해주세요.';
    if (trimmed.length > maxLength) {
      return '후기는 $maxLength자 이내로 작성해주세요. (현재 ${trimmed.length}자)';
    }
    return null;
  }
}
