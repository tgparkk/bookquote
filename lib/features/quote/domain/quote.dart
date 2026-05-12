// 인용구 도메인 모델.
//
// `public.quotes` 테이블 row와 1:1 — `Quote.fromJson(supabaseRow)`로 직접 만든다.
// DB는 snake_case, Dart는 camelCase라 불일치 필드만 `@JsonKey`로 매핑.
// moods는 text[] ↔ List<QuoteMood> 변환을 [QuoteMoodListConverter]가 담당
// (알 수 없는 무드 name은 드롭). 카드 디자인 상태는 여기 두지 않는다 (Stage 3 cards).

import 'package:freezed_annotation/freezed_annotation.dart';

import 'quote_mood.dart';

part 'quote.freezed.dart';
part 'quote.g.dart';

/// quotes.moods (text[]) ↔ `List<QuoteMood>`. 알 수 없는 name은 드롭.
class QuoteMoodListConverter
    implements JsonConverter<List<QuoteMood>, List<dynamic>> {
  const QuoteMoodListConverter();

  @override
  List<QuoteMood> fromJson(List<dynamic> json) {
    final result = <QuoteMood>[];
    for (final v in json) {
      final m = QuoteMood.fromName(v.toString());
      if (m != null) result.add(m);
    }
    return result;
  }

  @override
  List<dynamic> toJson(List<QuoteMood> object) =>
      object.map((m) => m.name).toList();
}

/// 인용구의 출처(입력 방식). DB CHECK: ('manual', 'clipboard'). 앱 내장 OCR은 안 쓴다
/// (폰 기능 + 클립보드 붙여넣기 — DECISIONS 2026-05-11).
enum QuoteSource { manual, clipboard }

@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'book_id') String? bookId,
    @JsonKey(name: 'manual_book_text') String? manualBookText,
    required String text,
    int? page,
    @JsonKey(unknownEnumValue: QuoteSource.manual)
    @Default(QuoteSource.manual) QuoteSource source,
    @QuoteMoodListConverter() @Default(<QuoteMood>[]) List<QuoteMood> moods,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Quote;

  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
}

/// 새 인용구 생성/오프라인 큐잉 시 클라이언트가 보낼 입력. JSON 직렬화 가능 —
/// 아웃박스(`shared_preferences`)에 그대로 저장하고, DB insert 시 snake_case 키가
/// 그대로 쓰인다 (`user_id`만 repository가 덧붙임).
@freezed
abstract class QuoteInput with _$QuoteInput {
  const factory QuoteInput({
    required String text,
    @JsonKey(name: 'book_id') String? bookId,
    @JsonKey(name: 'manual_book_text') String? manualBookText,
    int? page,
    @JsonKey(unknownEnumValue: QuoteSource.manual)
    @Default(QuoteSource.manual) QuoteSource source,
    @QuoteMoodListConverter() @Default(<QuoteMood>[]) List<QuoteMood> moods,
  }) = _QuoteInput;

  factory QuoteInput.fromJson(Map<String, dynamic> json) =>
      _$QuoteInputFromJson(json);
}
