// CardRepository design jsonb 페이로드 스키마 회귀 검증.
//
// `CardEditorState.toJson()`이 cards.design 컬럼에 그대로 INSERT 된다.
// 이 페이로드 모양이 깨지면 마이그레이션의 jsonb 구조와 어긋남 — 시점의
// design 스냅샷이 무의미해진다. 향후 PR12에서 fontStep/textAnchor 등을
// 추가할 때 이 테스트가 회귀 가드.
//
// `recordShare` 자체는 Supabase live client 의존이라 V1엔 통합 검증
// 없이 fire-and-forget 계약(swallow)만 코드로 보존.

import 'package:bookquote/core/theme/tokens.dart';
import 'package:bookquote/features/card_editor/state/card_editor_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardEditorState → cards.design jsonb 페이로드', () {
    test('templateId/ratio/watermarkEnabled/fontStep 4키 포함 (PR12-B에서 fontStep 추가)', () {
      const state = CardEditorState(
        templateId: 'mono',
        ratio: CardRatio.post,
        watermarkEnabled: false,
      );
      final json = state.toJson();
      expect(
        json.keys.toSet(),
        {'templateId', 'ratio', 'watermarkEnabled', 'fontStep'},
      );
    });

    test('ratio는 enum.name 문자열(story/feed/post)로 직렬화', () {
      for (final r in CardRatio.values) {
        final json = CardEditorState(
          templateId: 'minimal',
          ratio: r,
          watermarkEnabled: true,
        ).toJson();
        expect(json['ratio'], r.name);
      }
    });

    test('watermarkEnabled는 bool — true/false', () {
      expect(
        CardEditorState(
          templateId: 'warm',
          ratio: CardRatio.feed,
          watermarkEnabled: true,
        ).toJson()['watermarkEnabled'],
        isTrue,
      );
      expect(
        CardEditorState(
          templateId: 'warm',
          ratio: CardRatio.feed,
          watermarkEnabled: false,
        ).toJson()['watermarkEnabled'],
        isFalse,
      );
    });
  });
}
