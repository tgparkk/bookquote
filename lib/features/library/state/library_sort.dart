// 서재 [책] 탭 정렬·상태 필터 (2026-09-26).
//
// 정렬은 SharedPreferences(`lib.sort`)에 저장하고 보기 방식 4종 모두에 적용한다
// (구 "책장 모드만 가나다순" 고정 규칙 대체). 상태 필터는 화면 세션 상태 — 저장 안 함.
// 상태 판정은 `libraryStatusOf`(날짜 우선, 날짜·상태 기록 없는 책은 [전체]에만).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../book/domain/library_entry.dart';
import '../../book/domain/reading_dates.dart';

enum LibrarySort {
  recentlyAdded,
  title,
  author,
  rating,
  quoteCount;

  /// 정렬 시트 라벨.
  String get label => switch (this) {
        LibrarySort.recentlyAdded => '최근 담은 순',
        LibrarySort.title => '제목순',
        LibrarySort.author => '저자순',
        LibrarySort.rating => '내 별점 높은 순',
        LibrarySort.quoteCount => '인용 많은 순',
      };

  /// 툴바 버튼의 짧은 라벨.
  String get shortLabel => switch (this) {
        LibrarySort.recentlyAdded => '최근순',
        LibrarySort.title => '제목순',
        LibrarySort.author => '저자순',
        LibrarySort.rating => '별점순',
        LibrarySort.quoteCount => '인용순',
      };
}

class LibrarySortNotifier extends AsyncNotifier<LibrarySort> {
  static const _prefsKey = 'lib.sort';

  @override
  Future<LibrarySort> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    for (final s in LibrarySort.values) {
      if (s.name == raw) return s;
    }
    return LibrarySort.recentlyAdded;
  }

  Future<void> set(LibrarySort sort) async {
    state = AsyncData(sort);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, sort.name);
  }
}

final librarySortProvider =
    AsyncNotifierProvider<LibrarySortNotifier, LibrarySort>(
  LibrarySortNotifier.new,
);

/// [filter]가 null이면 전체, 아니면 그 상태로 판정된 책만(순서 유지).
List<LibraryEntry> filterLibrary(
  List<LibraryEntry> entries,
  ReadingStatus? filter,
) {
  if (filter == null) return entries;
  return [
    for (final e in entries)
      if (libraryStatusOf(e) == filter) e,
  ];
}

/// [sort]로 정렬한 새 목록. 동률·값 없음은 최근 담은 순으로 — 결과가 결정적이게.
/// 저자·별점이 없는 책은 뒤로. [quoteCounts]는 `quoteCount` 정렬에서만 쓴다.
List<LibraryEntry> sortLibrary(
  List<LibraryEntry> entries,
  LibrarySort sort, {
  Map<String, int> quoteCounts = const {},
}) {
  int byRecent(LibraryEntry a, LibraryEntry b) =>
      b.addedAt.compareTo(a.addedAt);

  final int Function(LibraryEntry, LibraryEntry) primary = switch (sort) {
    LibrarySort.recentlyAdded => (_, _) => 0,
    LibrarySort.title => (a, b) => a.book.title.compareTo(b.book.title),
    LibrarySort.author => (a, b) {
        final x = a.book.author?.trim() ?? '';
        final y = b.book.author?.trim() ?? '';
        if (x.isEmpty != y.isEmpty) return x.isEmpty ? 1 : -1;
        final c = x.compareTo(y);
        return c != 0 ? c : a.book.title.compareTo(b.book.title);
      },
    LibrarySort.rating => (a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0),
    LibrarySort.quoteCount => (a, b) =>
        (quoteCounts[b.book.id] ?? 0).compareTo(quoteCounts[a.book.id] ?? 0),
  };

  return [...entries]..sort((a, b) {
      final c = primary(a, b);
      return c != 0 ? c : byRecent(a, b);
    });
}
