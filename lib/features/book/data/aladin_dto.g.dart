// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aladin_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AladinSearchResponse _$AladinSearchResponseFromJson(
  Map<String, dynamic> json,
) => _AladinSearchResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => AladinBookDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalResults: (json['totalResults'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  size: (json['size'] as num).toInt(),
);

Map<String, dynamic> _$AladinSearchResponseToJson(
  _AladinSearchResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'totalResults': instance.totalResults,
  'page': instance.page,
  'size': instance.size,
};

_AladinBookDto _$AladinBookDtoFromJson(Map<String, dynamic> json) =>
    _AladinBookDto(
      isbn13: json['isbn13'] as String,
      isbn10: json['isbn10'] as String?,
      title: json['title'] as String,
      author: json['author'] as String?,
      publisher: json['publisher'] as String?,
      pubDate: json['pubDate'] as String?,
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String?,
      categoryName: json['categoryName'] as String?,
      itemId: json['itemId'] as String?,
    );

Map<String, dynamic> _$AladinBookDtoToJson(_AladinBookDto instance) =>
    <String, dynamic>{
      'isbn13': instance.isbn13,
      'isbn10': instance.isbn10,
      'title': instance.title,
      'author': instance.author,
      'publisher': instance.publisher,
      'pubDate': instance.pubDate,
      'coverUrl': instance.coverUrl,
      'description': instance.description,
      'categoryName': instance.categoryName,
      'itemId': instance.itemId,
    };

_EdgeError _$EdgeErrorFromJson(Map<String, dynamic> json) => _EdgeError(
  code: json['code'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$EdgeErrorToJson(_EdgeError instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};
