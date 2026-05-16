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

import '../../core/theme/tokens.dart';
import 'data/card_renderer.dart';
import 'data/card_repository.dart';
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

  Future<void> _share() async {
    if (_sharing || _data == null) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
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
    context.go('/quote/${widget.quoteId}/card');
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
  });

  final GlobalKey captureKey;
  final CardTemplate template;
  final QuoteCardData data;
  final CardRatio ratio;
  final bool watermarkEnabled;
  final int fontStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteAsync = ref.watch(extractedPaletteProvider((
      coverUrl: data.coverUrl,
      templateId: template.id,
    )));
    final palette = paletteAsync.value ?? QuoteCard.fallbackFor(template);
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
