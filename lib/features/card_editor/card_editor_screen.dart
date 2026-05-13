// 카드 에디터 — Stage 3 PR7 단계.
//
// 이번 PR(7): 5종 템플릿 위젯·디스패처를 만들어 시각적 검증을 가능하게 한다.
// quote 본문은 mock 데이터(`_mock`)를 쓰며, 실제 `quoteByIdProvider` +
// 책 join은 PR9(에디터 MVP)에서 controller와 함께 들어온다.
// PR8: palette_service(LRU 표지 색 추출 + ensureContrast)
// PR10: card_renderer (RepaintBoundary PNG) + share_sheet

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import 'domain/card_template.dart';
import 'domain/quote_card_data.dart';
import 'presentation/widgets/quote_card.dart';
import 'state/palette_providers.dart';

class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  // PR7 임시 데이터. PR9에서 quoteByIdProvider(widget.quoteId) +
  // bookByIdProvider(quote.bookId)를 합쳐 QuoteCardData로 변환한다.
  static const QuoteCardData _mock = QuoteCardData(
    quoteText: '우리는 누군가의 가장 좋은 시절을 잘 모르는 채로도, 그 사람을 사랑할 수 있다.',
    bookTitle: '작별하지 않는다',
    bookAuthor: '한강',
    bookPublisher: '문학동네',
  );

  CardRatio _ratio = CardRatio.story;
  late CardTemplate _template = CardTemplate.recommended(
    charCount: _mock.charCount,
    hasCover: _mock.hasCover,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary300,
      appBar: AppBar(
        title: const Text('카드 만들기'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s3),
            child: Center(child: _RatioSegment(
              value: _ratio,
              onChanged: (r) => setState(() => _ratio = r),
            )),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s6),
                  child: _PreviewBox(
                    template: _template,
                    data: _mock,
                    ratio: _ratio,
                  ),
                ),
              ),
            ),
            _TemplateStrip(
              selected: _template,
              data: _mock,
              ratio: _ratio,
              onSelect: (t) => setState(() => _template = t),
            ),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      ),
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
    required this.template,
    required this.data,
    required this.ratio,
  });

  final CardTemplate template;
  final QuoteCardData data;
  final CardRatio ratio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 표지 색 추출(있으면) → 미도착 동안엔 templateId 폴백 팔레트로 즉시 렌더.
    // `card-editor.md §3 로딩: 팔레트 추출 대기` — fallback 렌더 후 cross-fade.
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
          child: FittedBox(
            fit: BoxFit.contain,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: QuoteCard(
                key: ValueKey<String>('${template.id}-${data.coverUrl ?? ""}'),
                template: template,
                data: data,
                palette: palette,
                ratio: ratio,
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
