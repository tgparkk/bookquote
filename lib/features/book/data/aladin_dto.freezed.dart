// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aladin_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AladinSearchResponse {

 List<AladinBookDto> get items; int get totalResults; int get page; int get size;
/// Create a copy of AladinSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AladinSearchResponseCopyWith<AladinSearchResponse> get copyWith => _$AladinSearchResponseCopyWithImpl<AladinSearchResponse>(this as AladinSearchResponse, _$identity);

  /// Serializes this AladinSearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AladinSearchResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalResults, totalResults) || other.totalResults == totalResults)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalResults,page,size);

@override
String toString() {
  return 'AladinSearchResponse(items: $items, totalResults: $totalResults, page: $page, size: $size)';
}


}

/// @nodoc
abstract mixin class $AladinSearchResponseCopyWith<$Res>  {
  factory $AladinSearchResponseCopyWith(AladinSearchResponse value, $Res Function(AladinSearchResponse) _then) = _$AladinSearchResponseCopyWithImpl;
@useResult
$Res call({
 List<AladinBookDto> items, int totalResults, int page, int size
});




}
/// @nodoc
class _$AladinSearchResponseCopyWithImpl<$Res>
    implements $AladinSearchResponseCopyWith<$Res> {
  _$AladinSearchResponseCopyWithImpl(this._self, this._then);

  final AladinSearchResponse _self;
  final $Res Function(AladinSearchResponse) _then;

/// Create a copy of AladinSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalResults = null,Object? page = null,Object? size = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AladinBookDto>,totalResults: null == totalResults ? _self.totalResults : totalResults // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AladinSearchResponse].
extension AladinSearchResponsePatterns on AladinSearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AladinSearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AladinSearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AladinSearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _AladinSearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AladinSearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AladinSearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AladinBookDto> items,  int totalResults,  int page,  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AladinSearchResponse() when $default != null:
return $default(_that.items,_that.totalResults,_that.page,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AladinBookDto> items,  int totalResults,  int page,  int size)  $default,) {final _that = this;
switch (_that) {
case _AladinSearchResponse():
return $default(_that.items,_that.totalResults,_that.page,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AladinBookDto> items,  int totalResults,  int page,  int size)?  $default,) {final _that = this;
switch (_that) {
case _AladinSearchResponse() when $default != null:
return $default(_that.items,_that.totalResults,_that.page,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AladinSearchResponse implements AladinSearchResponse {
  const _AladinSearchResponse({required final  List<AladinBookDto> items, required this.totalResults, required this.page, required this.size}): _items = items;
  factory _AladinSearchResponse.fromJson(Map<String, dynamic> json) => _$AladinSearchResponseFromJson(json);

 final  List<AladinBookDto> _items;
@override List<AladinBookDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int totalResults;
@override final  int page;
@override final  int size;

/// Create a copy of AladinSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AladinSearchResponseCopyWith<_AladinSearchResponse> get copyWith => __$AladinSearchResponseCopyWithImpl<_AladinSearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AladinSearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AladinSearchResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalResults, totalResults) || other.totalResults == totalResults)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalResults,page,size);

@override
String toString() {
  return 'AladinSearchResponse(items: $items, totalResults: $totalResults, page: $page, size: $size)';
}


}

/// @nodoc
abstract mixin class _$AladinSearchResponseCopyWith<$Res> implements $AladinSearchResponseCopyWith<$Res> {
  factory _$AladinSearchResponseCopyWith(_AladinSearchResponse value, $Res Function(_AladinSearchResponse) _then) = __$AladinSearchResponseCopyWithImpl;
@override @useResult
$Res call({
 List<AladinBookDto> items, int totalResults, int page, int size
});




}
/// @nodoc
class __$AladinSearchResponseCopyWithImpl<$Res>
    implements _$AladinSearchResponseCopyWith<$Res> {
  __$AladinSearchResponseCopyWithImpl(this._self, this._then);

  final _AladinSearchResponse _self;
  final $Res Function(_AladinSearchResponse) _then;

/// Create a copy of AladinSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalResults = null,Object? page = null,Object? size = null,}) {
  return _then(_AladinSearchResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AladinBookDto>,totalResults: null == totalResults ? _self.totalResults : totalResults // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AladinBookDto {

 String get isbn13; String? get isbn10; String get title; String? get author; String? get publisher; String? get pubDate; String? get coverUrl; String? get description; String? get categoryName; String? get itemId;
/// Create a copy of AladinBookDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AladinBookDtoCopyWith<AladinBookDto> get copyWith => _$AladinBookDtoCopyWithImpl<AladinBookDto>(this as AladinBookDto, _$identity);

  /// Serializes this AladinBookDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AladinBookDto&&(identical(other.isbn13, isbn13) || other.isbn13 == isbn13)&&(identical(other.isbn10, isbn10) || other.isbn10 == isbn10)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.pubDate, pubDate) || other.pubDate == pubDate)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.itemId, itemId) || other.itemId == itemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isbn13,isbn10,title,author,publisher,pubDate,coverUrl,description,categoryName,itemId);

@override
String toString() {
  return 'AladinBookDto(isbn13: $isbn13, isbn10: $isbn10, title: $title, author: $author, publisher: $publisher, pubDate: $pubDate, coverUrl: $coverUrl, description: $description, categoryName: $categoryName, itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class $AladinBookDtoCopyWith<$Res>  {
  factory $AladinBookDtoCopyWith(AladinBookDto value, $Res Function(AladinBookDto) _then) = _$AladinBookDtoCopyWithImpl;
@useResult
$Res call({
 String isbn13, String? isbn10, String title, String? author, String? publisher, String? pubDate, String? coverUrl, String? description, String? categoryName, String? itemId
});




}
/// @nodoc
class _$AladinBookDtoCopyWithImpl<$Res>
    implements $AladinBookDtoCopyWith<$Res> {
  _$AladinBookDtoCopyWithImpl(this._self, this._then);

  final AladinBookDto _self;
  final $Res Function(AladinBookDto) _then;

/// Create a copy of AladinBookDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isbn13 = null,Object? isbn10 = freezed,Object? title = null,Object? author = freezed,Object? publisher = freezed,Object? pubDate = freezed,Object? coverUrl = freezed,Object? description = freezed,Object? categoryName = freezed,Object? itemId = freezed,}) {
  return _then(_self.copyWith(
isbn13: null == isbn13 ? _self.isbn13 : isbn13 // ignore: cast_nullable_to_non_nullable
as String,isbn10: freezed == isbn10 ? _self.isbn10 : isbn10 // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,pubDate: freezed == pubDate ? _self.pubDate : pubDate // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AladinBookDto].
extension AladinBookDtoPatterns on AladinBookDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AladinBookDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AladinBookDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AladinBookDto value)  $default,){
final _that = this;
switch (_that) {
case _AladinBookDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AladinBookDto value)?  $default,){
final _that = this;
switch (_that) {
case _AladinBookDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String isbn13,  String? isbn10,  String title,  String? author,  String? publisher,  String? pubDate,  String? coverUrl,  String? description,  String? categoryName,  String? itemId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AladinBookDto() when $default != null:
return $default(_that.isbn13,_that.isbn10,_that.title,_that.author,_that.publisher,_that.pubDate,_that.coverUrl,_that.description,_that.categoryName,_that.itemId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String isbn13,  String? isbn10,  String title,  String? author,  String? publisher,  String? pubDate,  String? coverUrl,  String? description,  String? categoryName,  String? itemId)  $default,) {final _that = this;
switch (_that) {
case _AladinBookDto():
return $default(_that.isbn13,_that.isbn10,_that.title,_that.author,_that.publisher,_that.pubDate,_that.coverUrl,_that.description,_that.categoryName,_that.itemId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String isbn13,  String? isbn10,  String title,  String? author,  String? publisher,  String? pubDate,  String? coverUrl,  String? description,  String? categoryName,  String? itemId)?  $default,) {final _that = this;
switch (_that) {
case _AladinBookDto() when $default != null:
return $default(_that.isbn13,_that.isbn10,_that.title,_that.author,_that.publisher,_that.pubDate,_that.coverUrl,_that.description,_that.categoryName,_that.itemId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AladinBookDto implements AladinBookDto {
  const _AladinBookDto({required this.isbn13, this.isbn10, required this.title, this.author, this.publisher, this.pubDate, this.coverUrl, this.description, this.categoryName, this.itemId});
  factory _AladinBookDto.fromJson(Map<String, dynamic> json) => _$AladinBookDtoFromJson(json);

@override final  String isbn13;
@override final  String? isbn10;
@override final  String title;
@override final  String? author;
@override final  String? publisher;
@override final  String? pubDate;
@override final  String? coverUrl;
@override final  String? description;
@override final  String? categoryName;
@override final  String? itemId;

/// Create a copy of AladinBookDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AladinBookDtoCopyWith<_AladinBookDto> get copyWith => __$AladinBookDtoCopyWithImpl<_AladinBookDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AladinBookDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AladinBookDto&&(identical(other.isbn13, isbn13) || other.isbn13 == isbn13)&&(identical(other.isbn10, isbn10) || other.isbn10 == isbn10)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.pubDate, pubDate) || other.pubDate == pubDate)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.itemId, itemId) || other.itemId == itemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isbn13,isbn10,title,author,publisher,pubDate,coverUrl,description,categoryName,itemId);

@override
String toString() {
  return 'AladinBookDto(isbn13: $isbn13, isbn10: $isbn10, title: $title, author: $author, publisher: $publisher, pubDate: $pubDate, coverUrl: $coverUrl, description: $description, categoryName: $categoryName, itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class _$AladinBookDtoCopyWith<$Res> implements $AladinBookDtoCopyWith<$Res> {
  factory _$AladinBookDtoCopyWith(_AladinBookDto value, $Res Function(_AladinBookDto) _then) = __$AladinBookDtoCopyWithImpl;
@override @useResult
$Res call({
 String isbn13, String? isbn10, String title, String? author, String? publisher, String? pubDate, String? coverUrl, String? description, String? categoryName, String? itemId
});




}
/// @nodoc
class __$AladinBookDtoCopyWithImpl<$Res>
    implements _$AladinBookDtoCopyWith<$Res> {
  __$AladinBookDtoCopyWithImpl(this._self, this._then);

  final _AladinBookDto _self;
  final $Res Function(_AladinBookDto) _then;

/// Create a copy of AladinBookDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isbn13 = null,Object? isbn10 = freezed,Object? title = null,Object? author = freezed,Object? publisher = freezed,Object? pubDate = freezed,Object? coverUrl = freezed,Object? description = freezed,Object? categoryName = freezed,Object? itemId = freezed,}) {
  return _then(_AladinBookDto(
isbn13: null == isbn13 ? _self.isbn13 : isbn13 // ignore: cast_nullable_to_non_nullable
as String,isbn10: freezed == isbn10 ? _self.isbn10 : isbn10 // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,pubDate: freezed == pubDate ? _self.pubDate : pubDate // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EdgeError {

 String get code; String get message;
/// Create a copy of EdgeError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EdgeErrorCopyWith<EdgeError> get copyWith => _$EdgeErrorCopyWithImpl<EdgeError>(this as EdgeError, _$identity);

  /// Serializes this EdgeError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EdgeError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'EdgeError(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $EdgeErrorCopyWith<$Res>  {
  factory $EdgeErrorCopyWith(EdgeError value, $Res Function(EdgeError) _then) = _$EdgeErrorCopyWithImpl;
@useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class _$EdgeErrorCopyWithImpl<$Res>
    implements $EdgeErrorCopyWith<$Res> {
  _$EdgeErrorCopyWithImpl(this._self, this._then);

  final EdgeError _self;
  final $Res Function(EdgeError) _then;

/// Create a copy of EdgeError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EdgeError].
extension EdgeErrorPatterns on EdgeError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EdgeError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EdgeError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EdgeError value)  $default,){
final _that = this;
switch (_that) {
case _EdgeError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EdgeError value)?  $default,){
final _that = this;
switch (_that) {
case _EdgeError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EdgeError() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message)  $default,) {final _that = this;
switch (_that) {
case _EdgeError():
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _EdgeError() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EdgeError implements EdgeError {
  const _EdgeError({required this.code, required this.message});
  factory _EdgeError.fromJson(Map<String, dynamic> json) => _$EdgeErrorFromJson(json);

@override final  String code;
@override final  String message;

/// Create a copy of EdgeError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EdgeErrorCopyWith<_EdgeError> get copyWith => __$EdgeErrorCopyWithImpl<_EdgeError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EdgeErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EdgeError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'EdgeError(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$EdgeErrorCopyWith<$Res> implements $EdgeErrorCopyWith<$Res> {
  factory _$EdgeErrorCopyWith(_EdgeError value, $Res Function(_EdgeError) _then) = __$EdgeErrorCopyWithImpl;
@override @useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class __$EdgeErrorCopyWithImpl<$Res>
    implements _$EdgeErrorCopyWith<$Res> {
  __$EdgeErrorCopyWithImpl(this._self, this._then);

  final _EdgeError _self;
  final $Res Function(_EdgeError) _then;

/// Create a copy of EdgeError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(_EdgeError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
