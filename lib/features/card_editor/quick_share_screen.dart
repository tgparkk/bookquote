// 바로 공유 화면 — Stage 3 PR10.5.
//
// 디자이너 권고(2026-05-16): 홈 카드에서 매번 에디터를 강제하면 차별화
// "단톡 1탭"에 마찰. 이 화면은 진입 즉시 draft(또는 추천 디자인)로 카드를
// 렌더 → 공유 시트를 자동으로 띄운다. 시트 dismiss 후에도 화면을 유지해
// [다시 공유]/[디자인 편집] 출구를 제공(④ 막다른 골목 금지).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_init.dart';
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

class QuickShareScreen extends ConsumerStatefulWidget {
  const QuickShareScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  ConsumerState<QuickShareScreen> createState() => _QuickShareScreenState();
}

class _QuickShareScreenState extends ConsumerState<QuickShareScreen> {
  final GlobalKey _captureKey = GlobalKey();

  QuoteCardData? _data;
  bool _ready = false;
  bool _notFound = false;
  bool _loadError = false;
  String? _diagMessage;  // 진단용 — release logcat에 flutter 로그가 안 잡혀서 화면 직접 표시.
  bool _sharing = false;
  bool _autoSheetTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    try {
      final data =
          await ref.read(quoteCardDataProvider(widget.quoteId).future);
      if (!mounted) return;
      if (data == null) {
        setState(() {
          _notFound = true;
          _ready = true;
        });
        return;
      }
      final controller = ref.read(cardEditorControllerProvider.notifier);
      controller.attach(widget.quoteId);
      final draft = await controller.readDraft();
      if (!mounted) return;
      if (draft != null) {
        controller.applyState(draft);
      } else {
        controller.applyRecommended(
          charCount: data.charCount,
          hasCover: data.hasCover,
        );
      }
      setState(() {
        _data = data;
        _ready = true;
      });
      // PR16-C-2: 잠금 + 키 없음이면 _LockedView로 렌더되므로 자동 공유 X.
      if (data.isLockedAndUnreadable) {
        _autoSheetTriggered = true; // 사용자 [다시 공유] 누름 방지 — 버튼도 숨김.
        return;
      }
      // 카드 위젯 build → endOfFrame 2회로 layout/paint + 폰트 안전망.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _autoSheetTriggered) return;
      _autoSheetTriggered = true;
      await _share();
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loadError = true;
        _diagMessage = '${e.runtimeType}: $e\n${st.toString().split('\n').take(4).join('\n')}';
        _ready = true;
      });
    }
  }

  /// PR16-D: _LockedView [잠금 해제] 핸들러. UnlockDialog → 마스터키 캐시.
  /// 성공 시 quote 재로드 + bootstrap 재실행 → 자동 시트 흐름 정상 진입.
  Future<void> _onUnlockTap() async {
    final ok = await ensureMasterKeyReady(context, ref);
    if (!ok || !mounted) return;
    ref.invalidate(quoteCardDataProvider(widget.quoteId));
    setState(() {
      _data = null;
      _ready = false;
      _autoSheetTriggered = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _share() async {
    if (_sharing || _data == null) return;
    // PR16-C-2: 잠금 인용구 공유 직전 평문 경고. 자동 시트(_bootstrap 끝) 첫 진입과
    // 수동 [다시 공유] 탭 둘 다 이 헬퍼로 흘러 동일 경고를 본다.
    if (_data!.isPrivate) {
      final ok = await showPrivateShareWarningDialog(context);
      if (!ok || !mounted) return;
    }
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // B12: 자동 트리거 케이스 — endOfFrame 2회 후에도 RepaintBoundary가 zero
      // size일 수 있다(폰트/이미지 async, release 마이크로태스크 타이밍). 한 frame
      // 더 기다려 재확인 → 그래도 zero면 renderCardPng가 명확한 CardRenderException.
      var size = _captureKey.currentContext?.size;
      if (size == null || size.isEmpty) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        size = _captureKey.currentContext?.size;
      }
      final state = ref.read(cardEditorControllerProvider);
      final file = await renderCardPng(
        boundaryKey: _captureKey,
        ratio: state.ratio,
      );
      if (!mounted) return;
      // PR11: 시트 직전 fire-and-forget으로 공유 이력 기록.
      unawaited(
        ref.read(cardRepositoryProvider).recordShare(
              quoteId: widget.quoteId,
              bookId: _data!.bookId,
              design: state,
            ),
      );
      await showCardShareSheet(
        context: context,
        file: file,
        shareText: _data!.quoteText,
        bookId: _data!.bookId,
        senderUid: supabase.auth.currentUser?.id,
      );
    } on CardRenderException {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('카드 만들기에 실패했어요. 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _openEditor() {
    // PR14-G W8: push로 변경 — 기존 go는 quick_share 스택을 교체해 카드 에디터에서
    // 뒤로가기 시 홈으로 직행, "디자인 편집 → 다시 공유" 시나리오(S6)가 단절됨.
    // push로 두면 에디터에서 뒤로 = quick_share 복귀 + [다시 공유] 1탭. 본 화면의
    // `_autoSheetTriggered=true`라 복귀 시 자동 시트는 재발하지 않음.
    context.push('/quote/${widget.quoteId}/card');
  }

  @override
  Widget build(BuildContext context) {
    // autoDispose 프로바이더 2개를 항상 watch해 listener를 active로 유지한다.
    // - cardEditorControllerProvider: _bootstrap이 ref.read(...notifier) 후
    //   applyState/applyRecommended를 부르는데, watch 없으면 disposed notifier
    //   대입으로 throw.
    // - quoteCardDataProvider: family라 read만 하면 첫 async gap에서 ref가 dispose →
    //   provider 본문의 두 번째 ref.watch가 UnmountedRefException throw.
    // (2026-05-16 실기기에서 양쪽 모두 재현 — release에선 마이크로태스크 타이밍 차이로
    // debug보다 발현 빈도 높음.)
    ref.watch(cardEditorControllerProvider);
    ref.watch(quoteCardDataProvider(widget.quoteId));
    return Scaffold(
      backgroundColor: AppColors.secondary300,
      appBar: AppBar(
        title: const Text('이 디자인으로 보낼까요?'),
        leading: IconButton(
          tooltip: '닫기',
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: <Widget>[
          if (_data != null)
            TextButton.icon(
              onPressed: _openEditor,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('디자인 편집'),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notFound) return const _NotFoundView();
    if (_loadError) {
      return _ErrorView(
        diagMessage: _diagMessage,
        onRetry: () {
          setState(() {
            _loadError = false;
            _diagMessage = null;
            _ready = false;
            _autoSheetTriggered = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
        },
      );
    }
    // PR16-C-2: 잠금 + 키 없음 — 카드 미리보기·[다시 공유] 버튼 자체를 숨기고 안내.
    // PR16-D: [잠금 해제] 콜백 — 성공 시 quote 재로드 + bootstrap 재실행.
    if (_data?.isLockedAndUnreadable ?? false) {
      return _LockedView(onUnlock: _onUnlockTap);
    }

    final state = ref.watch(cardEditorControllerProvider);
    final template = CardTemplate.byId(state.templateId);
    final data = _data!;

    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: _PreviewBox(
                captureKey: _captureKey,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            0,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('다시 공유'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent500,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: FontWeight.w600,
                fontSize: AppFontSize.base,
              ),
            ),
          ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const <BoxShadow>[AppShadows.card],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: ratio.size.aspectRatio,
          child: RepaintBoundary(
            key: captureKey,
            child: FittedBox(
              fit: BoxFit.contain,
              child: QuoteCard(
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
  const _ErrorView({required this.onRetry, this.diagMessage});

  final VoidCallback onRetry;
  final String? diagMessage;

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
            if (diagMessage != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s3),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                decoration: BoxDecoration(
                  color: AppColors.semanticErrorLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: SelectableText(
                  diagMessage!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.semanticError,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s4),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

/// 잠금 인용구이지만 이 기기에서 본문 복호화 키가 준비되지 않은 상태.
/// PR16-C-2 — 자동 시트·공유 진입을 봉쇄하고 사용자에게 해제 경로 안내.
/// PR16-D — [잠금 해제] 1탭으로 같은 화면에서 UnlockDialog 진입.
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
