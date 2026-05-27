// PR29: 서재 [책] 탭의 view 모드 상태.
//
// list/grid/stack/shelf 4종. 사용자가 마지막에 고른 모드를 SharedPreferences에
// 저장해 다음 진입 시 복원. 기본값은 list — 데이터 무관하게 즉시 표시 가능하고
// 가장 친숙한 형태. stack/shelf는 page_count가 있는 책만 위쪽에 노출되고 없는
// 책은 "두께 미수집" 섹션에 모인다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LibraryViewMode {
  list,
  grid,
  stack,
  shelf;

  /// BottomSheet 라벨.
  String get label => switch (this) {
        LibraryViewMode.list => '리스트',
        LibraryViewMode.grid => '표지 그리드',
        LibraryViewMode.stack => '쌓아 보기',
        LibraryViewMode.shelf => '책장',
      };

  String get description => switch (this) {
        LibraryViewMode.list => '제목·저자·출판사를 한 줄씩',
        LibraryViewMode.grid => '표지만 한눈에 모자이크로',
        LibraryViewMode.stack => '책 두께대로 위로 쌓기',
        LibraryViewMode.shelf => '실제 책장처럼 가로로 꽂기',
      };

  IconData get icon => switch (this) {
        LibraryViewMode.list => Icons.view_list_outlined,
        LibraryViewMode.grid => Icons.grid_view_outlined,
        LibraryViewMode.stack => Icons.view_agenda_outlined,
        LibraryViewMode.shelf => Icons.auto_stories_outlined,
      };
}

const String _kPrefsKey = 'lib.viewMode';

class LibraryViewModeNotifier extends AsyncNotifier<LibraryViewMode> {
  @override
  Future<LibraryViewMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null) return LibraryViewMode.list;
    for (final m in LibraryViewMode.values) {
      if (m.name == raw) return m;
    }
    return LibraryViewMode.list;
  }

  Future<void> set(LibraryViewMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, mode.name);
  }
}

final libraryViewModeProvider =
    AsyncNotifierProvider<LibraryViewModeNotifier, LibraryViewMode>(
  LibraryViewModeNotifier.new,
);
