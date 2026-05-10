// 책 도메인 모델.
// `public.books` 테이블 row와 1:1 — `Book.fromJson(supabaseRow)`로 직접 만든다.
// DB는 snake_case, Dart는 camelCase라 불일치 필드만 `@JsonKey`로 매핑.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String isbn13,
    String? isbn10,
    required String title,
    String? author,
    String? publisher,
    @JsonKey(name: 'pub_date') String? pubDate,
    @JsonKey(name: 'cover_url') String? coverUrl,
    String? description,
    @JsonKey(name: 'category_name') String? categoryName,
    @Default('aladin') String source,
    @JsonKey(name: 'source_id') String? sourceId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
