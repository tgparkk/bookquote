// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Book _$BookFromJson(Map<String, dynamic> json) => _Book(
  id: json['id'] as String,
  isbn13: json['isbn13'] as String,
  isbn10: json['isbn10'] as String?,
  title: json['title'] as String,
  author: json['author'] as String?,
  publisher: json['publisher'] as String?,
  pubDate: json['pub_date'] as String?,
  coverUrl: json['cover_url'] as String?,
  description: json['description'] as String?,
  categoryName: json['category_name'] as String?,
  source: json['source'] as String? ?? 'aladin',
  sourceId: json['source_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BookToJson(_Book instance) => <String, dynamic>{
  'id': instance.id,
  'isbn13': instance.isbn13,
  'isbn10': instance.isbn10,
  'title': instance.title,
  'author': instance.author,
  'publisher': instance.publisher,
  'pub_date': instance.pubDate,
  'cover_url': instance.coverUrl,
  'description': instance.description,
  'category_name': instance.categoryName,
  'source': instance.source,
  'source_id': instance.sourceId,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
