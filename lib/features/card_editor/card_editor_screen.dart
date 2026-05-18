// 카드 에디터 — Stage 3 PR9.
//
// quote+book 실데이터(`quoteCardDataProvider`)를 기반으로 `CardEditorController`가
// templateId/ratio/watermarkEnabled를 보유. 진입 시 저장된 draft가 있으면
// "이어서 만들기" 다이얼로그(`card-editor.md §4 편집 상태 영속화`).
//
// 후속 PR:
// - PR10: card_renderer (RepaintBoundary.toImage) + share_sheet — AppBar 공유 버튼
// - PR11: cards 테이블 + 공유 성공 시 비차단 INSERT
// - PR12: 5스와치 적용/다른 느낌 ↻/언두·redo/폰트 ±/auto-fit 경고/접근성

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../crypto/presentation/lock_dialogs.dart';
import 'data/card_renderer.dart';
import 'data/card_repository.dart';
import 'data/color_utils.dart';
import 'domain/card_template.dart';
import 'domain/quote_card_data.dart';
import 'presentation/widgets/quote_card.dart';
import 'presentation/widgets/share_sheet.dart';
import 'state/card_editor_controller.dart';
import 'state/palette_providers.dart';
import 'state/quote_card_data_provider.dart';

enum _AppBarAction { editQuote, toggleWatermark }

/// 비율별 안전한 인용구 길이 휴리스틱 — 이 임계를 넘으면 카드에 다 안 들어갈 위험.
/// 1080×{1920/1080/1350} 캔버스에서 NotoSerifKR 15~22px·행간 1.6~1.8 기준 측정값.
/// `screens/card-editor.md §7`의 auto-fit 경고 트리거. PR12-D.
const Map<CardRatio, int> _ratioCharLimit = <CardRatio, int>{
  CardRatio.feed: 300,
  CardRatio.post: 450,
  CardRatio.story: 600,
};

/// 현재 인용구 길이와 비율로 "더 잘 어울리는" 비율을 추천. 현재가 충분히 크면 null.
/// 모든 비율 초과 시에도 가장 큰 비율(story) 추천 — 사용자가 그 다음 어떻게 할지 결정.
CardRatio? _recommendRatio(int charCount, CardRatio current) {
  final entries = _ratioCharLimit.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (final e in entries) {
    if (e.value >= charCount && e.key != current) return e.key;
  }
  return null;
}

class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  bool _initialized = false;
  bool _isSharing = false;
  // 본문 수정 후 복귀 시 다이얼로그 없이 silent로 초기화 (B3). 사용자가 같은
  // 세션 흐름이라 "이어서 만들기" 재질문은 마찰 — draft 있으면 그대로 적용.
  bool _skipDraftDialog = false;
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(cardEditorControllerProvider.notifier).attach(widget.quoteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(quoteCardDataProvider(widget.quoteId));
    final data = dataAsync.value;
    return Scaffold(
      backgroundColor: AppColors.secondary300,
      appBar: _buildAppBar(data),
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            onRetry: () =>
                ref.invalidate(quoteCardDataProvider(widget.quoteId)),
          ),
          data: (data) {
            if (data == null) return const _NotFoundView();
            // PR16-C-2: 잠금 + 키 없음 — 편집·공유 자체를 막고 안내. controller
            // 초기화도 건너뜀(잠금 인용구라 추천 디자인 의미 없음).
            // PR16-D: [잠금 해제] 1탭으로 같은 화면에서 UnlockDialog 진입.
            if (data.isLockedAndUnreadable) {
              return _LockedView(onUnlock: _onUnlockTap);
            }
            if (!_initialized) {
              _initialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeFromData(data);
              });
            }
            return _Editor(data: data, captureKey: _captureKey);
          },
        ),
      ),
      // F4: [공유] 버튼을 AppBar 우상단 → 하단 Full-width로 이동. 한 손 엄지 도달
      // 보장(S1·S14 페르소나). data 있을 때만 노출. 잠금 + 키 없음이면 숨김.
      bottomNavigationBar:
          data == null || data.isLockedAndUnreadable ? null : _buildShareBar(data),
    );
  }

  Widget _buildShareBar(QuoteCardData data) {
    final ratio = ref.watch(cardEditorControllerProvider).ratio;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s2,
          AppSpacing.s4,
          AppSpacing.s2,
        ),
        child: FilledButton.icon(
          onPressed: _isSharing ? null : () => _onShareTap(data, ratio),
          icon: _isSharing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text('공유'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent500,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.base,
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(QuoteCardData? data) {
    if (data == null) {
      return AppBar(title: const Text('카드 만들기'));
    }
    final state = ref.watch(cardEditorControllerProvider);
    final controller = ref.read(cardEditorControllerProvider.notifier);
    return AppBar(
      title: const Text('카드 만들기'),
      actions: <Widget>[
        IconButton(
          tooltip: state.canUndo ? '되돌리기' : '되돌릴 작업 없음',
          onPressed: state.canUndo ? controller.undo : null,
          icon: Icon(
            Icons.undo_rounded,
            color: state.canUndo
                ? AppColors.primary600
                : AppColors.primary300,
          ),
        ),
        // F4: [공유] 버튼은 하단 bottomNavigationBar(`_buildShareBar`)로 이동.
        // AppBar에는 undo + overflow 메뉴만 잔류.
        // 부차 액션은 overflow 메뉴로 묶어 폭 확보.
        PopupMenuButton<_AppBarAction>(
          tooltip: '더보기',
          icon: const Icon(Icons.more_vert, color: AppColors.primary600),
          onSelected: (v) {
            switch (v) {
              case _AppBarAction.editQuote:
                _onEditQuoteTap();
              case _AppBarAction.toggleWatermark:
                controller.toggleWatermark();
                // F10: 토글 후 상태를 명시적으로 안내. 팝업 메뉴가 닫혀 사용자가
                // 현재 ON/OFF 상태를 시각적으로 즉시 파악하기 어려웠음.
                if (!mounted) return;
                final next = ref.read(cardEditorControllerProvider);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    content: Text(
                      next.watermarkEnabled ? '워터마크를 켰어요' : '워터마크를 껐어요',
                    ),
                    duration: const Duration(milliseconds: 1500),
                  ));
            }
          },
          itemBuilder: (_) => <PopupMenuEntry<_AppBarAction>>[
            const PopupMenuItem<_AppBarAction>(
              value: _AppBarAction.editQuote,
              child: Row(
                children: <Widget>[
                  Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary600),
                  SizedBox(width: AppSpacing.s2),
                  Text('본문 수정'),
                ],
              ),
            ),
            PopupMenuItem<_AppBarAction>(
              value: _AppBarAction.toggleWatermark,
              child: Row(
                children: <Widget>[
                  Icon(
                    state.watermarkEnabled
                        ? Icons.copyright_rounded
                        : Icons.copyright_outlined,
                    size: 18,
                    color: state.watermarkEnabled
                        ? AppColors.accent500
                        : AppColors.primary600,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(state.watermarkEnabled ? '워터마크 끄기' : '워터마크 켜기'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 본문 수정 진입점. quote 입력 화면을 편집 모드로 열고, 복귀 시 카드 데이터를
  /// invalidate해 미리보기에 변경 본문이 즉시 반영되도록 한다.
  ///
  /// B3: `_initialized=false`로 리셋해 새 data가 도착하면 `_initializeFromData`가
  /// 재실행되도록 한다. 단 `_skipDraftDialog=true`로 표시해 "이어서 만들기"
  /// 다이얼로그 재발 없이 silent 적용(같은 작업 흐름이므로).
  Future<void> _onEditQuoteTap() async {
    await context.push('/quote/new?quoteId=${widget.quoteId}');
    if (!mounted) return;
    ref.invalidate(quoteCardDataProvider(widget.quoteId));
    setState(() {
      _initialized = false;
      _skipDraftDialog = true;
    });
  }

  /// PR16-D: _LockedView [잠금 해제] 핸들러. UnlockDialog로 마스터키 캐시.
  /// 성공 시 quote provider invalidate → 새 fetch에서 본문 복호화 → 정상 에디터
  /// 화면이 자동 재진입. `_initialized=false`로 controller 재초기화 트리거.
  Future<void> _onUnlockTap() async {
    final ok = await ensureMasterKeyReady(context, ref);
    if (!ok || !mounted) return;
    ref.invalidate(quoteCardDataProvider(widget.quoteId));
    setState(() => _initialized = false);
  }

  Future<void> _onShareTap(QuoteCardData data, CardRatio ratio) async {
    if (_isSharing) return;
    // PR16-C-2: 잠금 인용구는 공유 직전 평문 경고 — 본문 잠금과 이미지 공유의
    // 의미를 혼동하지 않게. 사용자 [취소]면 공유 흐름 중단(_isSharing 토글 전).
    if (data.isPrivate) {
      final ok = await showPrivateShareWarningDialog(context);
      if (!ok || !mounted) return;
    }
    setState(() => _isSharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await renderCardPng(
        boundaryKey: _captureKey,
        ratio: ratio,
      );
      if (!mounted) return;
      // PR11: 시트가 열리는 시점에 fire-and-forget으로 공유 이력 기록.
      // await 안 함 — 실패해도 공유 자체 흐름엔 영향 없음(repository에서 swallow).
      unawaited(
        ref.read(cardRepositoryProvider).recordShare(
              quoteId: widget.quoteId,
              bookId: data.bookId,
              design: ref.read(cardEditorControllerProvider),
            ),
      );
      await showCardShareSheet(
        context: context,
        file: file,
        shareText: data.quoteText,
      );
    } on CardRenderException {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('카드 만들기에 실패했어요. 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _initializeFromData(QuoteCardData data) async {
    final controller = ref.read(cardEditorControllerProvider.notifier);
    final draft = await controller.readDraft();
    if (!mounted) return;

    // B3: 본문 수정 후 복귀 — 사용자가 작업 흐름 중이므로 다이얼로그 없이
    // draft가 있으면 그대로 유지(템플릿/비율 등 디자인 보존), 없으면 새 추천.
    if (_skipDraftDialog) {
      _skipDraftDialog = false;
      if (draft != null) {
        controller.applyState(draft);
      } else {
        controller.applyRecommended(
          charCount: data.charCount,
          hasCover: data.hasCover,
        );
      }
      return;
    }

    if (draft != null) {
      final restore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('편집하던 카드가 있어요'),
          content: const Text('이어서 만들까요, 새로 시작할까요?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('새로 시작'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('이어서 만들기'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (restore == true) {
        controller.applyState(draft);
      } else {
        await controller.clearDraft();
        if (!mounted) return;
        controller.applyRecommended(
          charCount: data.charCount,
          hasCover: data.hasCover,
        );
      }
    } else {
      controller.applyRecommended(
        charCount: data.charCount,
        hasCover: data.hasCover,
      );
    }
  }
}

class _Editor extends ConsumerWidget {
  const _Editor({required this.data, required this.captureKey});

  final QuoteCardData data;
  final GlobalKey captureKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardEditorControllerProvider);
    final controller = ref.read(cardEditorControllerProvider.notifier);
    final template = CardTemplate.byId(state.templateId);

    // F8: 템플릿 전환 직전 사용자가 폰트 ±로 조정해뒀다면, setTemplate이 fontStep을
    // 0으로 리셋한 사실을 SnackBar로 안내. 이미 0이면 toast 생략.
    void notifyFontReset() {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('템플릿이 바뀌면서 글자 크기는 기본으로 되돌렸어요.'),
          duration: Duration(milliseconds: 1800),
        ));
    }

    void selectTemplate(CardTemplate t) {
      final hadTweak = state.fontStep != 0;
      final willChange = state.templateId != t.id;
      controller.setTemplate(t.id);
      if (hadTweak && willChange) notifyFontReset();
    }

    void cycleTemplate() {
      final hadTweak = state.fontStep != 0;
      final beforeId = state.templateId;
      controller.cycleTemplate(
        charCount: data.charCount,
        hasCover: data.hasCover,
      );
      final afterId = ref.read(cardEditorControllerProvider).templateId;
      if (hadTweak && afterId != beforeId) notifyFontReset();
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _RatioSegment(
                value: state.ratio,
                onChanged: controller.setRatio,
              ),
              const SizedBox(width: AppSpacing.s3),
              _FontSteppers(
                step: state.fontStep,
                onDecrease: controller.decreaseFont,
                onIncrease: controller.increaseFont,
              ),
            ],
          ),
        ),
        if (data.charCount > (_ratioCharLimit[state.ratio] ?? 600))
          _AutoFitWarning(
            currentRatio: state.ratio,
            charCount: data.charCount,
            onApplyRatio: controller.setRatio,
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: _PreviewBox(
                captureKey: captureKey,
                template: template,
                data: data,
                ratio: state.ratio,
                watermarkEnabled: state.watermarkEnabled,
                fontStep: state.fontStep,
                paletteSlotIndex: state.paletteSlotIndex,
              ),
            ),
          ),
        ),
        _PaletteRow(
          template: template,
          data: data,
          selectedIndex: state.paletteSlotIndex,
          onSelect: controller.setPaletteSlot,
          onCycle: cycleTemplate,
        ),
        const SizedBox(height: AppSpacing.s2),
        _TemplateStrip(
          selected: template,
          data: data,
          ratio: state.ratio,
          onSelect: selectTemplate,
        ),
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }
}

class _RatioSegment extends StatelessWidget {
  const _RatioSegment({required this.value, required this.onChanged});

  final CardRatio value;
  final ValueChanged<CardRatio> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CardRatio>(
      // B16: textStyle override 제거 — 고정 fontSize.xs면 시스템 1.3x에서
      // 레이블이 잘려 보임. Theme(textTheme.labelLarge)에 위임해 textScaler 적용.
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const <ButtonSegment<CardRatio>>[
        ButtonSegment(value: CardRatio.feed, label: Text('1:1')),
        ButtonSegment(value: CardRatio.post, label: Text('4:5')),
        ButtonSegment(value: CardRatio.story, label: Text('9:16')),
      ],
      selected: <CardRatio>{value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// 인용구가 현재 비율에 다 안 들어갈 위험을 알린다. 더 잘 어울리는 비율이 있으면
/// 1탭으로 적용. `screens/card-editor.md §7` 명세 — "잘린 채 조용히 export 금지".
/// PR12-D.
class _AutoFitWarning extends StatelessWidget {
  const _AutoFitWarning({
    required this.currentRatio,
    required this.charCount,
    required this.onApplyRatio,
  });

  final CardRatio currentRatio;
  final int charCount;
  final ValueChanged<CardRatio> onApplyRatio;

  @override
  Widget build(BuildContext context) {
    final recommended = _recommendRatio(charCount, currentRatio);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: AppColors.semanticWarningLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.semanticWarning.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.semanticWarning,
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                recommended != null
                    ? '이 인용구는 ${currentRatio.label}에서 잘릴 수 있어요. ${recommended.label}을 추천해요.'
                    : '카드에 다 안 들어갈 수 있어요. 텍스트를 줄이거나 비율을 바꿔 보세요.',
                style: const TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.sm,
                  color: AppColors.semanticWarning,
                ),
              ),
            ),
            if (recommended != null) ...<Widget>[
              const SizedBox(width: AppSpacing.s2),
              TextButton(
                onPressed: () => onApplyRatio(recommended),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2,
                  ),
                  foregroundColor: AppColors.semanticWarning,
                ),
                child: Text('${recommended.label} 적용'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 표지에서 추출한 5색 thumbnail + "다른 느낌 ↻" 버튼. PR12-C.
/// 카드 미리보기와 템플릿 스트립 사이에 노출.
class _PaletteRow extends ConsumerWidget {
  const _PaletteRow({
    required this.template,
    required this.data,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCycle,
  });

  final CardTemplate template;
  final QuoteCardData data;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteAsync = ref.watch(extractedPaletteProvider((
      coverUrl: data.coverUrl,
      templateId: template.id,
    )));
    final palette = paletteAsync.value ?? QuoteCard.fallbackFor(template);
    final colors = <Color>[
      palette.dominant,
      palette.secondary,
      palette.vibrant,
      palette.darkVibrant,
      palette.muted,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < colors.length; i++)
            _Swatch(
              color: colors[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
              index: i,
            ),
          const SizedBox(width: AppSpacing.s2),
          IconButton(
            tooltip: '다른 느낌 — 다음 템플릿',
            onPressed: onCycle,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary600,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.index,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '표지에서 추출한 색 ${index + 1}${selected ? ", 선택됨" : ""}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // PR12-E: hit area 48dp 보장(WCAG/Material). visual은 28dp 유지.
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.accent500
                      : const Color(0x14000000),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 비율 행에 함께 노출하는 [A−][A+] 폰트 미세조정. PR12-B.
class _FontSteppers extends StatelessWidget {
  const _FontSteppers({
    required this.step,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int step;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final canDecrease = step > CardEditorState.fontStepMin;
    final canIncrease = step < CardEditorState.fontStepMax;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: '글자 작게',
          onPressed: canDecrease ? onDecrease : null,
          icon: Icon(
            Icons.text_decrease_rounded,
            color: canDecrease
                ? AppColors.primary600
                : AppColors.primary300,
          ),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: '글자 크게',
          onPressed: canIncrease ? onIncrease : null,
          icon: Icon(
            Icons.text_increase_rounded,
            color: canIncrease
                ? AppColors.primary600
                : AppColors.primary300,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _PreviewBox extends ConsumerWidget {
  const _PreviewBox({
    required this.captureKey,
    required this.template,
    required this.data,
    required this.ratio,
    required this.watermarkEnabled,
    required this.fontStep,
    required this.paletteSlotIndex,
  });

  final GlobalKey captureKey;
  final CardTemplate template;
  final QuoteCardData data;
  final CardRatio ratio;
  final bool watermarkEnabled;
  final int fontStep;
  final int paletteSlotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteAsync = ref.watch(extractedPaletteProvider((
      coverUrl: data.coverUrl,
      templateId: template.id,
    )));
    final rawPalette = paletteAsync.value ?? QuoteCard.fallbackFor(template);
    final palette = applyPaletteSlot(rawPalette, paletteSlotIndex);
    return Semantics(
      label: '카드 미리보기, ${template.name} 템플릿, 인용구: ${data.quoteText}',
      child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const <BoxShadow>[AppShadows.card],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: ratio.size.aspectRatio,
          // `card_renderer.renderCardPng`이 toImage 로 캡처하는 지점.
          // boundary.size = 화면 표시 크기, pixelRatio 로 1080 폭까지 업스케일.
          child: RepaintBoundary(
            key: captureKey,
            child: FittedBox(
              fit: BoxFit.contain,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: QuoteCard(
                  key: ValueKey<String>(
                    '${template.id}-${data.coverUrl ?? ""}-$watermarkEnabled-$fontStep-$paletteSlotIndex',
                  ),
                  template: template,
                  data: data,
                  palette: palette,
                  ratio: ratio,
                  watermarkEnabled: watermarkEnabled,
                  fontStep: fontStep,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _TemplateStrip extends StatelessWidget {
  const _TemplateStrip({
    required this.selected,
    required this.data,
    required this.ratio,
    required this.onSelect,
  });

  final CardTemplate selected;
  final QuoteCardData data;
  final CardRatio ratio;
  final ValueChanged<CardTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        itemCount: CardTemplate.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
        itemBuilder: (context, i) {
          final t = CardTemplate.all[i];
          final enabled = t.supports(
            charCount: data.charCount,
            hasCover: data.hasCover,
          );
          return _MiniCard(
            template: t,
            data: data,
            ratio: ratio,
            isSelected: t.id == selected.id,
            enabled: enabled,
            onTap: enabled ? () => onSelect(t) : null,
          );
        },
      ),
    );
  }
}

class _MiniCard extends ConsumerWidget {
  const _MiniCard({
    required this.template,
    required this.data,
    required this.ratio,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final CardTemplate template;
  final QuoteCardData data;
  final CardRatio ratio;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = enabled
        ? (ref
                .watch(extractedPaletteProvider((
                  coverUrl: data.coverUrl,
                  templateId: template.id,
                )))
                .value ??
            QuoteCard.fallbackFor(template))
        : QuoteCard.fallbackFor(template);
    return Semantics(
      label:
          '${template.name} 템플릿${isSelected ? ", 선택됨" : ""}${enabled ? "" : ", 표지 필요"}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 56,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: AppColors.primary200,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: enabled
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: QuoteCard(
                          template: template,
                          data: data,
                          palette: palette,
                          ratio: CardRatio.story,
                          watermarkEnabled: false,
                        ),
                      )
                    : Container(
                        color: AppColors.secondary400,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Text(
                          '표지 필요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.ui,
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
                            color: AppColors.primary600,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              template.name,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
                color: isSelected ? AppColors.accent500 : AppColors.primary600,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 24,
                color: AppColors.accent500,
              ),
          ],
        ),
      ),
    ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.primary400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '이 인용구를 찾을 수 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            const Text(
              '삭제됐거나 권한이 없는 인용구일 수 있어요.',
              style: TextStyle(color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.primary400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '카드 정보를 불러오지 못했어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s4),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

/// 잠금 인용구이지만 이 기기에서 본문 복호화 키가 준비되지 않은 상태.
/// PR16-C-2 — 편집·공유 진입을 봉쇄하고 사용자에게 잠금 해제 경로를 안내.
/// PR16-D — [잠금 해제] 1탭으로 이 화면에서 바로 UnlockDialog 진입.
class _LockedView extends StatelessWidget {
  const _LockedView({this.onUnlock});

  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: AppColors.primary400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '이 기기에서 잠긴 인용구',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            const Text(
              '본문이 잠겨 있어요. 잠금 비밀번호로 풀면\n카드로 만들 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.primary500),
            ),
            if (onUnlock != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s6),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.lock_open_outlined, size: 18),
                label: const Text('잠금 해제'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent500,
                  foregroundColor: AppColors.secondary50,
                  minimumSize: const Size.fromHeight(48),
                  textStyle: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontWeight: FontWeight.w600,
                    fontSize: AppFontSize.base,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
