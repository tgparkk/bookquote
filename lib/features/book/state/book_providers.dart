// 책 단건 조회용 providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/book_repository.dart';
import '../domain/book.dart';

/// `/book/:id` 라우트의 :id로 단건 조회. 캐시는 Riverpod 기본(autoDispose).
final bookByIdProvider =
    FutureProvider.autoDispose.family<Book?, String>((ref, id) async {
  final repo = ref.read(bookRepositoryProvider);
  return repo.getById(id);
});

/// ISBN13으로 단건 조회. AladinBookDto upsert 결과 캐싱 등에 사용.
final bookByIsbnProvider =
    FutureProvider.autoDispose.family<Book?, String>((ref, isbn13) async {
  final repo = ref.read(bookRepositoryProvider);
  return repo.getByIsbn(isbn13);
});
