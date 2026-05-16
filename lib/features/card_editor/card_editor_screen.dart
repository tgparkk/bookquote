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

class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  bool _initialized = false;
  bool _isSharing = false;
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
    return Scaffold(
      backgroundColor: AppColors.secondary300,
      appBar: _buildAppBar(dataAsync.value),
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            onRetry: () =>
                ref.invalidate(quoteCardDataProvider(widget.quoteId)),
          ),
          data: (data) {
            if (data == null) return const _NotFoundView();
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
          tooltip: state.watermarkEnabled ? '워터마크 끄기' : '워터마크 켜기',
          onPressed: controller.toggleWatermark,
          icon: Icon(
            state.watermarkEnabled
                ? Icons.copyright_rounded
                : Icons.copyright_outlined,
            color: state.watermarkEnabled
                ? AppColors.accent500
                : AppColors.primary400,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.s2),
          child: Center(
            child: _RatioSegment(
              value: state.ratio,
              onChanged: controller.setRatio,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.s3),
          child: Center(
            child: FilledButton.icon(
              onPressed: _isSharing ? null : () => _onShareTap(data, state.ratio),
              icon: _isSharing
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 16),
              label: const Text('공유'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent500,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                ),
                textStyle: const TextStyle(
                  fontFamily: AppFonts.ui,
                  fontWeight: FontWeight.w600,
                  fontSize: AppFontSize.sm,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onShareTap(QuoteCardData data, CardRatio ratio) async {
    if (_isSharing) return;
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

    return Column(
      children: <Widget>[
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
              ),
            ),
          ),
        ),
        _TemplateStrip(
          selected: template,
          data: data,
          ratio: state.ratio,
          onSelect: (t) => controller.setTemplate(t.id),
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
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: AppFontSize.xs),
        ),
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

class _PreviewBox extends ConsumerWidget {
  const _PreviewBox({
    required this.captureKey,
    required this.template,
    required this.data,
    required this.ratio,
    required this.watermarkEnabled,
  });

  final GlobalKey captureKey;
  final CardTemplate template;
  final QuoteCardData data;
  final CardRatio ratio;
  final bool watermarkEnabled;

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
                    '${template.id}-${data.coverUrl ?? ""}-$watermarkEnabled',
                  ),
                  template: template,
                  data: data,
                  palette: palette,
                  ratio: ratio,
                  watermarkEnabled: watermarkEnabled,
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
    return GestureDetector(
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
