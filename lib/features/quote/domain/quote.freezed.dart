// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Quote {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'book_id') String? get bookId;@JsonKey(name: 'manual_book_text') String? get manualBookText;/// 평문 본문. `isPrivate=false`면 항상 non-null. `isPrivate=true`면
/// 클라이언트가 [Quote.fromRow] 시점에 캐시된 마스터키로 복호화해 채우거나,
/// 키가 없으면 null로 남는다(UI는 [isPrivate]로 잠금 fallback 분기).
/// PR16-B에서 nullable로 전환됨.
 String? get text; int? get page;@JsonKey(unknownEnumValue: QuoteSource.manual) QuoteSource get source;@QuoteMoodListConverter() List<QuoteMood> get moods;/// E2EE 잠금 여부. true면 평문 컬럼(text/manual_book_text)은 NULL이고
/// `*_encrypted`만 채워진 상태로 DB에 있다. (PR16-A 스키마, PR16-B wiring)
@JsonKey(name: 'is_private') bool get isPrivate;/// 암호화 알고리즘 버전. V1=1(AES-256-GCM). 잠금 아니면 null.
@JsonKey(name: 'crypto_version') int? get cryptoVersion;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteCopyWith<Quote> get copyWith => _$QuoteCopyWithImpl<Quote>(this as Quote, _$identity);

  /// Serializes this Quote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quote&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.manualBookText, manualBookText) || other.manualBookText == manualBookText)&&(identical(other.text, text) || other.text == text)&&(identical(other.page, page) || other.page == page)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.moods, moods)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.cryptoVersion, cryptoVersion) || other.cryptoVersion == cryptoVersion)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,bookId,manualBookText,text,page,source,const DeepCollectionEquality().hash(moods),isPrivate,cryptoVersion,createdAt,updatedAt);

@override
String toString() {
  return 'Quote(id: $id, userId: $userId, bookId: $bookId, manualBookText: $manualBookText, text: $text, page: $page, source: $source, moods: $moods, isPrivate: $isPrivate, cryptoVersion: $cryptoVersion, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $QuoteCopyWith<$Res>  {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) _then) = _$QuoteCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'book_id') String? bookId,@JsonKey(name: 'manual_book_text') String? manualBookText, String? text, int? page,@JsonKey(unknownEnumValue: QuoteSource.manual) QuoteSource source,@QuoteMoodListConverter() List<QuoteMood> moods,@JsonKey(name: 'is_private') bool isPrivate,@JsonKey(name: 'crypto_version') int? cryptoVersion,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$QuoteCopyWithImpl<$Res>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._self, this._then);

  final Quote _self;
  final $Res Function(Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? bookId = freezed,Object? manualBookText = freezed,Object? text = freezed,Object? page = freezed,Object? source = null,Object? moods = null,Object? isPrivate = null,Object? cryptoVersion = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String?,manualBookText: freezed == manualBookText ? _self.manualBookText : manualBookText // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as QuoteSource,moods: null == moods ? _self.moods : moods // ignore: cast_nullable_to_non_nullable
as List<QuoteMood>,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,cryptoVersion: freezed == cryptoVersion ? _self.cryptoVersion : cryptoVersion // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Quote].
extension QuotePatterns on Quote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quote value)  $default,){
final _that = this;
switch (_that) {
case _Quote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quote value)?  $default,){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'book_id')  String? bookId, @JsonKey(name: 'manual_book_text')  String? manualBookText,  String? text,  int? page, @JsonKey(unknownEnumValue: QuoteSource.manual)  QuoteSource source, @QuoteMoodListConverter()  List<QuoteMood> moods, @JsonKey(name: 'is_private')  bool isPrivate, @JsonKey(name: 'crypto_version')  int? cryptoVersion, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.userId,_that.bookId,_that.manualBookText,_that.text,_that.page,_that.source,_that.moods,_that.isPrivate,_that.cryptoVersion,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'book_id')  String? bookId, @JsonKey(name: 'manual_book_text')  String? manualBookText,  String? text,  int? page, @JsonKey(unknownEnumValue: QuoteSource.manual)  QuoteSource source, @QuoteMoodListConverter()  List<QuoteMood> moods, @JsonKey(name: 'is_private')  bool isPrivate, @JsonKey(name: 'crypto_version')  int? cryptoVersion, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Quote():
return $default(_that.id,_that.userId,_that.bookId,_that.manualBookText,_that.text,_that.page,_that.source,_that.moods,_that.isPrivate,_that.cryptoVersion,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'book_id')  String? bookId, @JsonKey(name: 'manual_book_text')  String? manualBookText,  String? text,  int? page, @JsonKey(unknownEnumValue: QuoteSource.manual)  QuoteSource source, @QuoteMoodListConverter()  List<QuoteMood> moods, @JsonKey(name: 'is_private')  bool isPrivate, @JsonKey(name: 'crypto_version')  int? cryptoVersion, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.userId,_that.bookId,_that.manualBookText,_that.text,_that.page,_that.source,_that.moods,_that.isPrivate,_that.cryptoVersion,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Quote implements Quote {
  const _Quote({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'book_id') this.bookId, @JsonKey(name: 'manual_book_text') this.manualBookText, this.text, this.page, @JsonKey(unknownEnumValue: QuoteSource.manual) this.source = QuoteSource.manual, @QuoteMoodListConverter() final  List<QuoteMood> moods = const <QuoteMood>[], @JsonKey(name: 'is_private') this.isPrivate = false, @JsonKey(name: 'crypto_version') this.cryptoVersion, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _moods = moods;
  factory _Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'book_id') final  String? bookId;
@override@JsonKey(name: 'manual_book_text') final  String? manualBookText;
/// 평문 본문. `isPrivate=false`면 항상 non-null. `isPrivate=true`면
/// 클라이언트가 [Quote.fromRow] 시점에 캐시된 마스터키로 복호화해 채우거나,
/// 키가 없으면 null로 남는다(UI는 [isPrivate]로 잠금 fallback 분기).
/// PR16-B에서 nullable로 전환됨.
@override final  String? text;
@override final  int? page;
@override@JsonKey(unknownEnumValue: QuoteSource.manual) final  QuoteSource source;
 final  List<QuoteMood> _moods;
@override@JsonKey()@QuoteMoodListConverter() List<QuoteMood> get moods {
  if (_moods is EqualUnmodifiableListView) return _moods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moods);
}

/// E2EE 잠금 여부. true면 평문 컬럼(text/manual_book_text)은 NULL이고
/// `*_encrypted`만 채워진 상태로 DB에 있다. (PR16-A 스키마, PR16-B wiring)
@override@JsonKey(name: 'is_private') final  bool isPrivate;
/// 암호화 알고리즘 버전. V1=1(AES-256-GCM). 잠금 아니면 null.
@override@JsonKey(name: 'crypto_version') final  int? cryptoVersion;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteCopyWith<_Quote> get copyWith => __$QuoteCopyWithImpl<_Quote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quote&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.manualBookText, manualBookText) || other.manualBookText == manualBookText)&&(identical(other.text, text) || other.text == text)&&(identical(other.page, page) || other.page == page)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._moods, _moods)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.cryptoVersion, cryptoVersion) || other.cryptoVersion == cryptoVersion)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,bookId,manualBookText,text,page,source,const DeepCollectionEquality().hash(_moods),isPrivate,cryptoVersion,createdAt,updatedAt);

@override
String toString() {
  return 'Quote(id: $id, userId: $userId, bookId: $bookId, manualBookText: $manualBookText, text: $text, page: $page, source: $source, moods: $moods, isPrivate: $isPrivate, cryptoVersion: $cryptoVersion, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$QuoteCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$QuoteCopyWith(_Quote value, $Res Function(_Quote) _then) = __$QuoteCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'book_id') String? bookId,@JsonKey(name: 'manual_book_text') String? manualBookText, String? text, int? page,@JsonKey(unknownEnumValue: QuoteSource.manual) QuoteSource source,@QuoteMoodListConverter() List<QuoteMood> moods,@JsonKey(name: 'is_private') bool isPrivate,@JsonKey(name: 'crypto_version') int? cryptoVersion,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$QuoteCopyWithImpl<$Res>
    implements _$QuoteCopyWith<$Res> {
  __$QuoteCopyWithImpl(this._self, this._then);

  final _Quote _self;
  final $Res Function(_Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? bookId = freezed,Object? manualBookText = freezed,Object? text = freezed,Object? page = freezed,Object? source = null,Object? moods = null,Object? isPrivate = null,Object? cryptoVersion = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String?,manualBookText: freezed == manualBookText ? _self.manualBookText : manualBookText // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as QuoteSource,moods: null == moods ? _self._moods : moods // ignore: cast_nullable_to_non_nullable
as List<QuoteMood>,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,cryptoVersion: freezed == cryptoVersion ? _self.cryptoVersion : cryptoVersion // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$QuoteInput {

 String get text;@JsonKey(name: 'book_id') String? get bookId;@JsonKey(name: 'manual_book_text') String? get manualBookText; int? get page;@JsonKey(unknownEnumValue: QuoteSource.manual) QuoteSource get source;@QuoteMoodListConverter() List<QuoteMood> get moods;@JsonKey(name: 'is_private') bool get isPrivate;
/// Create a copy of QuoteInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteInputCopyWith<QuoteInput> get copyWith => _$QuoteInputCopyWithImpl<QuoteInput>(this as QuoteInput, _$identity);

  /// Serializes this QuoteInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteInput&&(identical(other.text, text) || other.text == text)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.manualBookText, manualBookText) || other.manualBookText == manualBookText)&&(identical(other.page, page) || other.page == page)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.moods, moods)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,bookId,manualBookText,page,source,const DeepCollectionEquality().hash(moods),isPrivate);

@override
String toString() {
  return 'QuoteInput(text: $text, bookId: $bookId, manualBookText: $manualBookText, page: $page, source: $source, moods: $moods, isPrivate: $isPrivate)';
}


}

/// @nodoc
abstract mixin class $QuoteInputCopyWith<$Res>  {
  factory $QuoteInputCopyWith(QuoteInput value, $Res Function(QuoteInput) _then) = _$QuoteInputCopyWithImpl;
@useResult
$Res call({
 String text,@JsonKey(name: 'book_id') String? bookId,@JsonKey(name: 'manual_book_text') String? manualBookText, int? page,@JsonKey(unknownEnumValue: QuoteSource.manual) QuoteSource source,@QuoteMoodListConverter() List<QuoteMood> moods,@JsonKey(name: 'is_private') bool isPrivate
});




}
/// @nodoc
class _$QuoteInputCopyWithImpl<$Res>
    implements $QuoteInputCopyWith<$Res> {
  _$QuoteInputCopyWithImpl(this._self, this._then);

  final QuoteInput _self;
  final $Res Function(QuoteInput) _then;

/// Create a copy of QuoteInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? bookId = freezed,Object? manualBookText = freezed,Object? page = freezed,Object? source = null,Object? moods = null,Object? isPrivate = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String?,manualBookText: freezed == manualBookText ? _self.manualBookText : manualBookText // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as QuoteSource,moods: null == moods ? _self.moods : moods // ignore: cast_nullable_to_non_nullable
as List<QuoteMood>,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuoteInput].
extension QuoteInputPatterns on QuoteInput {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuoteInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuoteInput() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuoteInput value)  $default,){
final _that = this;
switch (_that) {
case _QuoteInput():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuoteInput value)?  $default,){
final _that = this;
switch (_that) {
case _QuoteInput() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text, @JsonKey(name: 'book_id')  String? bookId, @JsonKey(name: 'manual_book_text')  String? manualBookText,  int? page, @JsonKey(unknownEnumValue: QuoteSource.manual)  QuoteSource source, @QuoteMoodListConverter()  List<QuoteMood> moods, @JsonKey(name: 'is_private')  bool isPrivate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuoteInput() when $default != null:
return $default(_that.text,_that.bookId,_that.manualBookText,_that.page,_that.source,_that.moods,_that.isPrivate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text, @JsonKey(name: 'book_id')  String? bookId, @JsonKey(name: 'manual_book_text')  String? manualBookText,  int? page, @JsonKey(unknownEnumValue: QuoteSource.manual)  QuoteSource source, @QuoteMoodListConverter()  List<QuoteMood> moods, @JsonKey(name: 'is_private')  bool isPrivate)  $default,) {final _that = this;
switch (_that) {
case _QuoteInput():
return $default(_that.text,_that.bookId,_that.manualBookText,_that.page,_that.source,_that.moods,_that.isPrivate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text, @JsonKey(name: 'book_id')  String? bookId, @JsonKey(name: 'manual_book_text')  String? manualBookText,  int? page, @JsonKey(unknownEnumValue: QuoteSource.manual)  QuoteSource source, @QuoteMoodListConverter()  List<QuoteMood> moods, @JsonKey(name: 'is_private')  bool isPrivate)?  $default,) {final _that = this;
switch (_that) {
case _QuoteInput() when $default != null:
return $default(_that.text,_that.bookId,_that.manualBookText,_that.page,_that.source,_that.moods,_that.isPrivate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuoteInput implements QuoteInput {
  const _QuoteInput({required this.text, @JsonKey(name: 'book_id') this.bookId, @JsonKey(name: 'manual_book_text') this.manualBookText, this.page, @JsonKey(unknownEnumValue: QuoteSource.manual) this.source = QuoteSource.manual, @QuoteMoodListConverter() final  List<QuoteMood> moods = const <QuoteMood>[], @JsonKey(name: 'is_private') this.isPrivate = false}): _moods = moods;
  factory _QuoteInput.fromJson(Map<String, dynamic> json) => _$QuoteInputFromJson(json);

@override final  String text;
@override@JsonKey(name: 'book_id') final  String? bookId;
@override@JsonKey(name: 'manual_book_text') final  String? manualBookText;
@override final  int? page;
@override@JsonKey(unknownEnumValue: QuoteSource.manual) final  QuoteSource source;
 final  List<QuoteMood> _moods;
@override@JsonKey()@QuoteMoodListConverter() List<QuoteMood> get moods {
  if (_moods is EqualUnmodifiableListView) return _moods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moods);
}

@override@JsonKey(name: 'is_private') final  bool isPrivate;

/// Create a copy of QuoteInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteInputCopyWith<_QuoteInput> get copyWith => __$QuoteInputCopyWithImpl<_QuoteInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteInputToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuoteInput&&(identical(other.text, text) || other.text == text)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.manualBookText, manualBookText) || other.manualBookText == manualBookText)&&(identical(other.page, page) || other.page == page)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._moods, _moods)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,bookId,manualBookText,page,source,const DeepCollectionEquality().hash(_moods),isPrivate);

@override
String toString() {
  return 'QuoteInput(text: $text, bookId: $bookId, manualBookText: $manualBookText, page: $page, source: $source, moods: $moods, isPrivate: $isPrivate)';
}


}

/// @nodoc
abstract mixin class _$QuoteInputCopyWith<$Res> implements $QuoteInputCopyWith<$Res> {
  factory _$QuoteInputCopyWith(_QuoteInput value, $Res Function(_QuoteInput) _then) = __$QuoteInputCopyWithImpl;
@override @useResult
$Res call({
 String text,@JsonKey(name: 'book_id') String? bookId,@JsonKey(name: 'manual_book_text') String? manualBookText, int? page,@JsonKey(unknownEnumValue: QuoteSource.manual) QuoteSource source,@QuoteMoodListConverter() List<QuoteMood> moods,@JsonKey(name: 'is_private') bool isPrivate
});




}
/// @nodoc
class __$QuoteInputCopyWithImpl<$Res>
    implements _$QuoteInputCopyWith<$Res> {
  __$QuoteInputCopyWithImpl(this._self, this._then);

  final _QuoteInput _self;
  final $Res Function(_QuoteInput) _then;

/// Create a copy of QuoteInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? bookId = freezed,Object? manualBookText = freezed,Object? page = freezed,Object? source = null,Object? moods = null,Object? isPrivate = null,}) {
  return _then(_QuoteInput(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String?,manualBookText: freezed == manualBookText ? _self.manualBookText : manualBookText // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as QuoteSource,moods: null == moods ? _self._moods : moods // ignore: cast_nullable_to_non_nullable
as List<QuoteMood>,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
