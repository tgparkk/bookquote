// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Quote _$QuoteFromJson(Map<String, dynamic> json) => _Quote(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  bookId: json['book_id'] as String?,
  manualBookText: json['manual_book_text'] as String?,
  text: json['text'] as String,
  page: (json['page'] as num?)?.toInt(),
  source:
      $enumDecodeNullable(
        _$QuoteSourceEnumMap,
        json['source'],
        unknownValue: QuoteSource.manual,
      ) ??
      QuoteSource.manual,
  moods: json['moods'] == null
      ? const <QuoteMood>[]
      : const QuoteMoodListConverter().fromJson(json['moods'] as List),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$QuoteToJson(_Quote instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'book_id': instance.bookId,
  'manual_book_text': instance.manualBookText,
  'text': instance.text,
  'page': instance.page,
  'source': _$QuoteSourceEnumMap[instance.source]!,
  'moods': const QuoteMoodListConverter().toJson(instance.moods),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$QuoteSourceEnumMap = {
  QuoteSource.manual: 'manual',
  QuoteSource.clipboard: 'clipboard',
};

_QuoteInput _$QuoteInputFromJson(Map<String, dynamic> json) => _QuoteInput(
  text: json['text'] as String,
  bookId: json['book_id'] as String?,
  manualBookText: json['manual_book_text'] as String?,
  page: (json['page'] as num?)?.toInt(),
  source:
      $enumDecodeNullable(
        _$QuoteSourceEnumMap,
        json['source'],
        unknownValue: QuoteSource.manual,
      ) ??
      QuoteSource.manual,
  moods: json['moods'] == null
      ? const <QuoteMood>[]
      : const QuoteMoodListConverter().fromJson(json['moods'] as List),
);

Map<String, dynamic> _$QuoteInputToJson(_QuoteInput instance) =>
    <String, dynamic>{
      'text': instance.text,
      'book_id': instance.bookId,
      'manual_book_text': instance.manualBookText,
      'page': instance.page,
      'source': _$QuoteSourceEnumMap[instance.source]!,
      'moods': const QuoteMoodListConverter().toJson(instance.moods),
    };
