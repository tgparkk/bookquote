// 책귀 — 앱 내 테마 모드 선택 (DM-C)
//
// 시스템/라이트/다크 중 선택을 SharedPreferences에 영속한다. 시작 시 main()이
// 저장값을 읽어 [initialThemeModeProvider]를 override → 첫 프레임부터 올바른 테마
// (테마 깜빡임 없음). 변경은 [ThemeModeNotifier.set]이 즉시 반영 + 저장.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String themeModePrefsKey = 'theme_mode';

/// 시작 시 main()에서 SharedPreferences로 읽은 초기값으로 override된다.
/// override 안 하면(테스트 등) 시스템 설정 추종.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  /// 테마 모드 변경 — 즉시 UI 반영 + SharedPreferences 영속.
  Future<void> set(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themeModePrefsKey, mode.name);
    } catch (_) {
      // 저장 실패는 무시 — 이번 세션엔 이미 적용됨.
    }
  }
}

/// 저장 문자열(`mode.name`) → ThemeMode. 알 수 없으면 시스템.
ThemeMode themeModeFromString(String? s) => switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

/// ThemeMode → 한국어 라벨.
String themeModeLabel(ThemeMode m) => switch (m) {
      ThemeMode.system => '시스템 설정',
      ThemeMode.light => '라이트',
      ThemeMode.dark => '다크',
    };
