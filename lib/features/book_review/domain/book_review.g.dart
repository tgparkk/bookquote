// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookReview _$BookReviewFromJson(Map<String, dynamic> json) => _BookReview(
  userId: json['user_id'] as String,
  bookId: json['book_id'] as String,
  text: json['text'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BookReviewToJson(_BookReview instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'book_id': instance.bookId,
      'text': instance.text,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
