// CardEditorController — 상태 변경 / persist round-trip / cycle 게이트.
// shared_preferences는 setMockInitialValues로 in-memory.

import 'package:bookquote/core/theme/tokens.dart';
import 'package:bookquote/features/card_editor/state/card_editor_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('CardEditorState', () {
    test('JSON round-trip 보존', () {
      const s = CardEditorState(
        templateId: 'mono',
        ratio: CardRatio.feed,
        watermarkEnabled: false,
      );
      expect(CardEditorState.fromJson(s.toJson()), s);
    });

    test('빈/손상 JSON은 default로 채워짐', () {
      final s = CardEditorState.fromJson(<String, Object?>{});
      expect(s, CardEditorState.initial);
    });

    test('모르는 ratio name은 story 폴백', () {
      final s = CardEditorState.fromJson(<String, Object?>{
        'templateId': 'warm',
        'ratio': 'unknown',
        'watermarkEnabled': true,
      });
      expect(s.ratio, CardRatio.story);
      expect(s.templateId, 'warm');
    });
  });

  group('CardEditorController 상태 변경', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    test('initial = CardEditorState.initial', () {
      expect(
        container.read(cardEditorControllerProvider),
        CardEditorState.initial,
      );
    });

    test('setTemplate/setRatio/toggleWatermark — 모두 반영', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.setTemplate('mono');
      ctrl.setRatio(CardRatio.feed);
      ctrl.toggleWatermark();
      expect(
        container.read(cardEditorControllerProvider),
        const CardEditorState(
          templateId: 'mono',
          ratio: CardRatio.feed,
          watermarkEnabled: false,
          undoDepth: 3,
        ),
      );
    });

    test('동일 값 setter는 state를 안 흔든다', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      final before = container.read(cardEditorControllerProvider);
      ctrl.setTemplate(before.templateId);
      ctrl.setRatio(before.ratio);
      expect(
        identical(container.read(cardEditorControllerProvider), before),
        isTrue,
      );
    });

    test('applyRecommended — 짧고 표지 없으면 Typography', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.applyRecommended(charCount: 10, hasCover: false);
      expect(
        container.read(cardEditorControllerProvider).templateId,
        'typography',
      );
    });

    test('applyRecommended — 표지 있고 길면 CoverExtract', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.applyRecommended(charCount: 100, hasCover: true);
      expect(
        container.read(cardEditorControllerProvider).templateId,
        'coverExtract',
      );
    });
  });

  group('undo (PR12-A)', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('초기 상태는 canUndo=false', () {
      expect(container.read(cardEditorControllerProvider).canUndo, isFalse);
    });

    test('setTemplate 후 canUndo=true → undo로 원상복귀', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.setTemplate('mono');
      expect(container.read(cardEditorControllerProvider).canUndo, isTrue);
      expect(container.read(cardEditorControllerProvider).templateId, 'mono');
      ctrl.undo();
      final s = container.read(cardEditorControllerProvider);
      expect(s.templateId, 'minimal');
      expect(s.canUndo, isFalse);
    });

    test('비율·워터마크·템플릿 3변경 → undo 3번 → 모두 복귀', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.setTemplate('warm');
      ctrl.setRatio(CardRatio.post);
      ctrl.toggleWatermark();
      expect(container.read(cardEditorControllerProvider).undoDepth, 3);

      ctrl
        ..undo()
        ..undo()
        ..undo();
      expect(
        container.read(cardEditorControllerProvider),
        CardEditorState.initial,
      );
    });

    test('빈 스택에서 undo는 no-op', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.undo();
      expect(
        container.read(cardEditorControllerProvider),
        CardEditorState.initial,
      );
    });

    test('20단계 cap — 25번 변경 후 undo 25번 시도해도 20번까지만 복귀', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      // 워터마크 토글을 25번 — 매 호출이 _pushUndo.
      for (var i = 0; i < 25; i++) {
        ctrl.toggleWatermark();
      }
      expect(container.read(cardEditorControllerProvider).undoDepth, 20);
      for (var i = 0; i < 25; i++) {
        ctrl.undo();
      }
      // 처음 5번 변경은 stack에서 evict됐으므로 그 상태가 "되돌릴 수 있는 가장 오래된"
      // 시점. 짝수 토글 → watermark=true 유지 또는 짝수 횟수만큼 토글된 결과.
      // 핵심: undoDepth가 0이고 더 이상 undo 불가.
      expect(container.read(cardEditorControllerProvider).undoDepth, 0);
      expect(container.read(cardEditorControllerProvider).canUndo, isFalse);
    });

    test('applyRecommended는 언두 stack에 push 안 함(자동 분기)', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.applyRecommended(charCount: 10, hasCover: false);
      expect(
        container.read(cardEditorControllerProvider).canUndo,
        isFalse,
        reason: 'applyRecommended는 자동 분기 — 사용자 명시 액션 아님',
      );
    });

    test('applyState(이어서 만들기)도 언두 stack에 push 안 함', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.applyState(const CardEditorState(
        templateId: 'mono',
        ratio: CardRatio.feed,
        watermarkEnabled: false,
      ));
      expect(container.read(cardEditorControllerProvider).canUndo, isFalse);
    });
  });

  group('setTemplate fontStep 리셋 (PR14-D F8)', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('setTemplate은 fontStep을 0으로 리셋한다 — 시각 점프 방지', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl
        ..increaseFont()
        ..increaseFont(); // step=2
      expect(container.read(cardEditorControllerProvider).fontStep, 2);

      ctrl.setTemplate('mono');
      expect(container.read(cardEditorControllerProvider).fontStep, 0,
          reason: '전환 시 시각 일관성 위해 fontStep 리셋');
      expect(
          container.read(cardEditorControllerProvider).templateId, 'mono');
    });

    test('undo는 setTemplate 직전 fontStep도 함께 복원한다', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl
        ..increaseFont()
        ..increaseFont(); // step=2
      ctrl.setTemplate('mono'); // step=0 + undo 푸시
      expect(container.read(cardEditorControllerProvider).fontStep, 0);

      ctrl.undo();
      expect(container.read(cardEditorControllerProvider).fontStep, 2,
          reason: 'undo로 직전 step 복원');
      expect(container.read(cardEditorControllerProvider).templateId,
          'minimal');
    });

    test('동일 templateId 재설정은 fontStep을 흔들지 않는다', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.increaseFont(); // step=1
      ctrl.setTemplate('minimal'); // 동일 — no-op
      expect(container.read(cardEditorControllerProvider).fontStep, 1);
    });
  });

  group('cycleTemplate — supports 게이트', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('모든 템플릿 enable 상태에서 5번 cycle → 원점', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.setTemplate('minimal');
      for (var i = 0; i < 5; i++) {
        ctrl.cycleTemplate(charCount: 20, hasCover: true);
      }
      expect(
        container.read(cardEditorControllerProvider).templateId,
        'minimal',
      );
    });

    test('표지 없고 long quote — coverExtract/typography 건너뛰기', () {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.setTemplate('mono');
      // 다음 = coverExtract(no cover 건너뜀) → typography(>50자 건너뜀) → minimal
      ctrl.cycleTemplate(charCount: 200, hasCover: false);
      expect(
        container.read(cardEditorControllerProvider).templateId,
        'minimal',
      );
    });
  });

  group('영속화', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('flushPersist 후 readDraft가 동일 상태 반환', () async {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.setTemplate('warm');
      ctrl.setRatio(CardRatio.post);
      ctrl.toggleWatermark();
      await ctrl.debugFlushPersist();

      final draft = await ctrl.readDraft();
      expect(
        draft,
        const CardEditorState(
          templateId: 'warm',
          ratio: CardRatio.post,
          watermarkEnabled: false,
        ),
      );
    });

    test('clearDraft 후 readDraft = null', () async {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      ctrl.setTemplate('warm');
      await ctrl.debugFlushPersist();
      expect(await ctrl.readDraft(), isNotNull);
      await ctrl.clearDraft();
      expect(await ctrl.readDraft(), isNull);
    });

    test('attach 안 하면 persist/read 모두 no-op', () async {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.setTemplate('warm');
      await ctrl.debugFlushPersist();
      expect(await ctrl.readDraft(), isNull);
    });

    test('quoteId가 다르면 draft도 별개', () async {
      // q1으로 저장
      final c1 = ProviderContainer();
      final ctrl1 = c1.read(cardEditorControllerProvider.notifier);
      ctrl1.attach('q1');
      ctrl1.setTemplate('warm');
      await ctrl1.debugFlushPersist();
      c1.dispose();

      // q2 controller에서는 q1 draft가 보이지 않아야
      final c2 = ProviderContainer();
      final ctrl2 = c2.read(cardEditorControllerProvider.notifier);
      ctrl2.attach('q2');
      expect(await ctrl2.readDraft(), isNull);
      c2.dispose();
    });

    test('applyState — persist 트리거 안 함(복원은 새 편집 아님)', () async {
      final ctrl = container.read(cardEditorControllerProvider.notifier);
      ctrl.attach('q1');
      const restored = CardEditorState(
        templateId: 'mono',
        ratio: CardRatio.feed,
        watermarkEnabled: false,
      );
      ctrl.applyState(restored);
      expect(container.read(cardEditorControllerProvider), restored);
      // persist debounce가 호출되지 않았으므로 cleared 상태에서 readDraft = null
      expect(await ctrl.readDraft(), isNull);
    });
  });
}
