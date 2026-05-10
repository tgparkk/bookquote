// Edge Function `aladin-search` 응답 DTO.
//
// 도메인 `Book`과 의도적으로 분리. V2에서 네이버 등 다른 메타 소스를 추가해도
// 도메인이 깨지지 않게 하기 위함.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'aladin_dto.freezed.dart';
part 'aladin_dto.g.dart';

@freezed
abstract class AladinSearchResponse with _$AladinSearchResponse {
  const factory AladinSearchResponse({
    required List<AladinBookDto> items,
    required int totalResults,
    required int page,
    required int size,
  }) = _AladinSearchResponse;

  factory AladinSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$AladinSearchResponseFromJson(json);
}

@freezed
abstract class AladinBookDto with _$AladinBookDto {
  const factory AladinBookDto({
    required String isbn13,
    String? isbn10,
    required String title,
    String? author,
    String? publisher,
    String? pubDate,
    String? coverUrl,
    String? description,
    String? categoryName,
    String? itemId,
  }) = _AladinBookDto;

  factory AladinBookDto.fromJson(Map<String, dynamic> json) =>
      _$AladinBookDtoFromJson(json);
}

/// Edge Function이 통일 사용하는 에러 envelope `{ error: { code, message } }`.
@freezed
abstract class EdgeError with _$EdgeError {
  const factory EdgeError({
    required String code,
    required String message,
  }) = _EdgeError;

  factory EdgeError.fromJson(Map<String, dynamic> json) =>
      _$EdgeErrorFromJson(json);
}
