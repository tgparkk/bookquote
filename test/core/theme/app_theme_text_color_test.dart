// 라이트/다크 테마 모두 테마 슬롯 텍스트 스타일에 색이 명시돼 있는지 검증.
//
// 테마 슬롯(AppBar 제목·Dialog 제목/본문·Chip 라벨)에 color 없는 TextStyle을
// 넣으면 M3 기본값(onSurface)을 덮어써 color=null → 엔진이 흰색으로 그린다.
// 라이트 테마에서 AppBar 제목과 다이얼로그 글씨가 배경에 묻혀 안 보이던 회귀
// (2026-10-10 에뮬레이터 실사용 점검) 방지.

import 'package:bookquote/core/theme/app_semantic_colors.dart';
import 'package:bookquote/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases = {
    'light': (AppTheme.light(), AppSemanticColors.light),
    'dark': (AppTheme.dark(), AppSemanticColors.dark),
  };

  for (final MapEntry(key: name, value: (theme, s)) in cases.entries) {
    group('$name 테마', () {
      test('AppBar 제목 색 = onSurface', () {
        expect(theme.appBarTheme.titleTextStyle?.color, s.onSurface);
      });

      test('Dialog 제목/본문 색 명시', () {
        expect(theme.dialogTheme.titleTextStyle?.color, s.onSurface);
        expect(theme.dialogTheme.contentTextStyle?.color, s.onSurfaceMuted);
      });

      test('Chip 라벨 색 명시', () {
        expect(theme.chipTheme.labelStyle?.color, isNotNull);
      });

      testWidgets('AppBar·AlertDialog 텍스트가 배경과 구분된다', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            appBar: AppBar(title: const Text('appbar')),
            body: const AlertDialog(
              title: Text('dialog-title'),
              content: Text('dialog-content'),
            ),
          ),
        ));

        for (final label in ['appbar', 'dialog-title', 'dialog-content']) {
          final color = DefaultTextStyle.of(
            tester.element(find.text(label)),
          ).style.color;
          expect(color, isNotNull, reason: '$label 색이 null이면 흰색으로 그려짐');
          final contrast = _contrast(color!, s.scaffoldBg);
          expect(contrast, greaterThan(4.5), reason: '$label 대비 $contrast');
        }
      });
    });
  }
}

/// WCAG 대비율.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
