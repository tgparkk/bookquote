// WCAG 2.1 대비 유틸 — 추출 팔레트의 텍스트 색 보장이 의존하는 코어.

import 'package:bookquote/core/theme/tokens.dart';
import 'package:bookquote/features/card_editor/data/color_utils.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);

void main() {
  group('relativeLuminance', () {
    test('흰색은 1.0', () {
      expect(relativeLuminance(_white), closeTo(1.0, 0.001));
    });
    test('검정은 0.0', () {
      expect(relativeLuminance(_black), closeTo(0.0, 0.001));
    });
    test('단조 증가 — 어두운 회색 < 밝은 회색', () {
      expect(
        relativeLuminance(const Color(0xFF333333)),
        lessThan(relativeLuminance(const Color(0xFFCCCCCC))),
      );
    });
  });

  group('contrastRatio', () {
    test('흰 vs 검정 = 21:1', () {
      expect(contrastRatio(_white, _black), closeTo(21.0, 0.05));
    });
    test('동일색은 1:1', () {
      expect(contrastRatio(_white, _white), closeTo(1.0, 0.001));
    });
    test('대칭 — ratio(a,b) == ratio(b,a)', () {
      const a = Color(0xFF0066CC);
      const b = Color(0xFFFFEEDD);
      expect(contrastRatio(a, b), closeTo(contrastRatio(b, a), 0.001));
    });
  });

  group('ensureContrast', () {
    test('대비 충분하면 foreground 그대로', () {
      expect(ensureContrast(_white, _black, minRatio: 4.5), _black);
      expect(ensureContrast(_black, _white, minRatio: 4.5), _white);
    });
    test('흰 배경 + 흰 글자 → primary900으로 교체', () {
      expect(
        ensureContrast(_white, _white, minRatio: 4.5),
        AppColors.primary900,
      );
    });
    test('검정 배경 + 검정 글자 → secondary200으로 교체', () {
      expect(
        ensureContrast(_black, _black, minRatio: 4.5),
        AppColors.secondary200,
      );
    });
    test('교체된 색은 minRatio 이상의 대비를 가진다(검증 가능 보증)', () {
      const bg = Color(0xFFCCCCAA); // 살짝 회색 배경
      final fg = ensureContrast(bg, bg, minRatio: 4.5);
      expect(contrastRatio(bg, fg), greaterThanOrEqualTo(4.5));
    });
  });

  group('getTextColorForBackground', () {
    test('밝은 배경 → primary900(검정 잉크)', () {
      expect(getTextColorForBackground(_white), AppColors.primary900);
      expect(
        getTextColorForBackground(const Color(0xFFFAFAF8)),
        AppColors.primary900,
      );
    });
    test('어두운 배경 → secondary200(종이 흰색)', () {
      expect(getTextColorForBackground(_black), AppColors.secondary200);
      expect(
        getTextColorForBackground(AppColors.monoBackground),
        AppColors.secondary200,
      );
    });
  });

  group('HSL 보조 함수', () {
    test('lightenToBackground — 채도<0.10이면 secondary400 폴백', () {
      // 거의 무채색 회색
      expect(
        lightenToBackground(const Color(0xFF7E7E7E)),
        AppColors.secondary400,
      );
    });
    test('lightenToBackground — 채색이 있으면 L 0.94 적용', () {
      const dominant = Color(0xFF8B0000); // dark red
      final out = lightenToBackground(dominant);
      final hsl = HSLColor.fromColor(out);
      expect(hsl.lightness, closeTo(0.94, 0.001));
    });
    test('toMidTone — 채도<0.10이면 primary600 폴백', () {
      expect(toMidTone(const Color(0xFF888888)), AppColors.primary600);
    });
    test('toMidTone — 채색이 있으면 L 0.40~0.55 클램프', () {
      // 매우 밝은 색
      const bright = Color(0xFFFFAA00);
      final out = toMidTone(bright);
      final hsl = HSLColor.fromColor(out);
      expect(hsl.lightness, inInclusiveRange(0.40, 0.55));
    });
  });
}
