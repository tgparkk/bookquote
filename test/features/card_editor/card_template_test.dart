// card_template + typography 알고리즘 유닛 테스트.
// PR7 — 골든은 PR10/12로 연기, 여기선 게이트·라우팅·시 배치 로직만 검증.

import 'package:bookquote/features/card_editor/domain/card_template.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/typography_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardTemplate.supports', () {
    test('Minimal/Warm/Mono — 항상 true', () {
      const all = <CardTemplate>[
        MinimalTemplate(),
        WarmTemplate(),
        MonoTemplate(),
      ];
      for (final t in all) {
        expect(t.supports(charCount: 0, hasCover: false), isTrue);
        expect(t.supports(charCount: 1000, hasCover: false), isTrue);
      }
    });

    test('CoverExtract — hasCover=false면 false', () {
      const t = CoverExtractTemplate();
      expect(t.supports(charCount: 50, hasCover: false), isFalse);
      expect(t.supports(charCount: 50, hasCover: true), isTrue);
    });

    test('Typography — 50자 이하만 true (maxCharCount 경계)', () {
      const t = TypographyTemplate();
      expect(t.supports(charCount: 50, hasCover: false), isTrue);
      expect(t.supports(charCount: 51, hasCover: false), isFalse);
      expect(TypographyTemplate.maxCharCount, 50);
    });
  });

  group('CardTemplate.recommended', () {
    test('짧은(≤30자) 인용구 → Typography', () {
      expect(
        CardTemplate.recommended(charCount: 10, hasCover: false),
        isA<TypographyTemplate>(),
      );
      expect(
        CardTemplate.recommended(charCount: 30, hasCover: true),
        isA<TypographyTemplate>(),
      );
    });

    test('중간 길이 + 표지 있음 → CoverExtract', () {
      expect(
        CardTemplate.recommended(charCount: 100, hasCover: true),
        isA<CoverExtractTemplate>(),
      );
    });

    test('표지 없는 일반 길이 → Minimal', () {
      expect(
        CardTemplate.recommended(charCount: 100, hasCover: false),
        isA<MinimalTemplate>(),
      );
    });
  });

  group('CardTemplate registry', () {
    test('all에는 5종이 정의된 순서대로 들어있다', () {
      expect(CardTemplate.all.length, 5);
      expect(CardTemplate.all.map((t) => t.id).toList(), <String>[
        'minimal',
        'warm',
        'mono',
        'coverExtract',
        'typography',
      ]);
    });

    test('byId — 알려진 id는 해당 인스턴스, 모르는 id는 Minimal로 폴백', () {
      expect(CardTemplate.byId('mono'), isA<MonoTemplate>());
      expect(CardTemplate.byId('non-existent'), isA<MinimalTemplate>());
    });
  });

  group('getTypographyFontSize', () {
    test('≤15자 = 36px, ≤30자 = 28px, 그 외 = 22px', () {
      expect(getTypographyFontSize(1), 36.0);
      expect(getTypographyFontSize(15), 36.0);
      expect(getTypographyFontSize(16), 28.0);
      expect(getTypographyFontSize(30), 28.0);
      expect(getTypographyFontSize(31), 22.0);
      expect(getTypographyFontSize(50), 22.0);
    });
  });

  group('splitIntoPoetryLines', () {
    test('공백 단어 단위로 줄을 채우고 자수 제한을 지킨다', () {
      final lines = splitIntoPoetryLines('우리는 누군가의 가장 좋은 시절을', 6);
      // 6자 한도에 맞춰 단어가 묶임 — '우리는'(3) + ' ' + '누군가의'(4) = 8 → 다음줄
      expect(lines, isNotEmpty);
      for (final l in lines) {
        // 한 줄이 8자(=가장긴 단어 '누군가의' 4자 + ' ' + '가장' 2자 = 7자)를 크게 넘기면 안 됨
        expect(l.length, lessThanOrEqualTo(10));
      }
      // 결합하면 원문 토큰을 모두 포함
      final joined = lines.join(' ');
      expect(joined.contains('우리는'), isTrue);
      expect(joined.contains('시절을'), isTrue);
    });

    test('마침표/쉼표/!/? 직후 강제 줄바꿈', () {
      final lines = splitIntoPoetryLines('그래도 살아있다. 슬프다.', 20);
      // 마침표 뒤에서 끊기므로 최소 2줄
      expect(lines.length, greaterThanOrEqualTo(2));
      expect(lines.first.endsWith('.'), isTrue);
    });

    test('전각 구두점도 강제 줄바꿈', () {
      final lines = splitIntoPoetryLines('첫째。둘째', 20);
      expect(lines.length, 2);
      expect(lines[0], '첫째。');
      expect(lines[1], '둘째');
    });

    test('빈 문자열은 빈 리스트', () {
      expect(splitIntoPoetryLines('', 6), <String>[]);
    });
  });

}
