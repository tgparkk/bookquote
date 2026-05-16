import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/color_utils.dart';
import '../../domain/quote_card_data.dart';
import 'card_watermark.dart';

/// T5 — 타이포 카드. `docs/design/templates/05-typography.md`.
///
/// 단문 전용(50자 이하 — `TypographyTemplate.maxCharCount`). 디스패처가 게이트하므로
/// 이 위젯에 도달했다면 이미 50자 이하다.
///
/// 시각 원칙: 텍스트가 조각처럼 공중에 뜨도록 수직 중앙 + 행간 2.2(poetry) + 단어 단위 줄바꿈.
class TypographyCard extends StatelessWidget {
  const TypographyCard({
    super.key,
    required this.data,
    required this.palette,
    required this.ratio,
    this.watermarkConfig = AppWatermark.minimal,
    this.watermarkEnabled = true,
    this.fontStep = 0,
  });

  final QuoteCardData data;
  final ExtractedPalette palette;
  final CardRatio ratio;
  final WatermarkConfig watermarkConfig;
  final bool watermarkEnabled;
  final int fontStep;

  static const Map<CardRatio, _Variant> _variants = <CardRatio, _Variant>{
    CardRatio.story: _Variant(
      width: 1080,
      height: 1920,
      paddingHorizontal: 96,
      bookFromBottom: 120,
      watermarkFromBottom: 72,
      maxCharsPerLine: 6,
    ),
    CardRatio.feed: _Variant(
      width: 1080,
      height: 1080,
      paddingHorizontal: 80,
      bookFromBottom: 96,
      watermarkFromBottom: 56,
      maxCharsPerLine: 5,
    ),
    CardRatio.post: _Variant(
      width: 1080,
      height: 1350,
      paddingHorizontal: 96,
      bookFromBottom: 104,
      watermarkFromBottom: 64,
      maxCharsPerLine: 6,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final v = _variants[ratio]!;
    final background = toMidTone(palette.muted);
    final fontSize = getEffectiveTypographyFontSize(data.charCount, fontStep);
    final lines = splitIntoPoetryLines(data.quoteText, v.maxCharsPerLine);

    return SizedBox(
      width: v.width,
      height: v.height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: ColoredBox(color: background)),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: v.paddingHorizontal),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final line in lines)
                      Text(
                        line,
                        style: TextStyle(
                          fontFamily: AppFonts.quote,
                          fontWeight: FontWeight.w700,
                          fontSize: fontSize,
                          height: AppLineHeight.poetry,
                          color: palette.textOnBackground,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: v.paddingHorizontal,
            bottom: v.bookFromBottom,
            child: _BookInfo(data: data, palette: palette),
          ),
          if (watermarkEnabled)
            Positioned(
              right: v.paddingHorizontal,
              bottom: v.watermarkFromBottom,
              child: Opacity(
                opacity: 0.20 / watermarkConfig.opacity,
                child: CardWatermark(
                  config: watermarkConfig,
                  color: palette.textOnBackground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookInfo extends StatelessWidget {
  const _BookInfo({required this.data, required this.palette});

  final QuoteCardData data;
  final ExtractedPalette palette;

  @override
  Widget build(BuildContext context) {
    final hasTitle = data.bookTitle != null && data.bookTitle!.isNotEmpty;
    final hasAuthor = data.bookAuthor != null && data.bookAuthor!.isNotEmpty;
    return Opacity(
      opacity: 0.60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasTitle)
            Text(
              data.bookTitle!,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: FontWeight.w400,
                fontSize: AppFontSize.xs,
                color: palette.subtextOnBackground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasAuthor) ...<Widget>[
            const SizedBox(height: AppSpacing.s1),
            Text(
              data.bookAuthor!,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: FontWeight.w400,
                fontSize: AppFontSize.xs,
                color: palette.subtextOnBackground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _Variant {
  const _Variant({
    required this.width,
    required this.height,
    required this.paddingHorizontal,
    required this.bookFromBottom,
    required this.watermarkFromBottom,
    required this.maxCharsPerLine,
  });

  final double width;
  final double height;
  final double paddingHorizontal;
  final double bookFromBottom;
  final double watermarkFromBottom;
  final int maxCharsPerLine;
}

/// T5 전용 폰트 크기. `templates/05.md §getTypographyFontSize`.
/// 일반 `getQuoteFontSize` 미사용 — 50자 이하 단문에 최적화된 임팩트 스케일.
double getTypographyFontSize(int charCount) {
  if (charCount <= 15) return 36.0;
  if (charCount <= 30) return 28.0;
  return 22.0;
}

/// T5 전용 — fontStep 반영. step 1당 2px 가감, [15, 48] clamp. PR12-B.
double getEffectiveTypographyFontSize(int charCount, int fontStep) {
  final base = getTypographyFontSize(charCount);
  return (base + fontStep * 2).clamp(15.0, 48.0);
}

/// 인용구를 시(詩) 배치용 줄 목록으로 변환.
/// `templates/05.md §splitIntoPoetryLines`.
///
/// 1) 쉼표·마침표·느낌표·물음표(한·영·전각 모두) 뒤에서 강제 줄바꿈
/// 2) 그 사이 각 chunk를 공백으로 단어 분리
/// 3) chunk별로 줄당 `maxCharsPerLine` 자수까지 누적해 line break
List<String> splitIntoPoetryLines(String text, int maxCharsPerLine) {
  final withForcedBreaks = text.replaceAllMapped(
    RegExp(r'([,，.。!！?？])\s*'),
    (m) => '${m[1]}\n',
  );

  final lines = <String>[];
  for (final chunk in withForcedBreaks.split('\n')) {
    final words = chunk
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) continue;

    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length > maxCharsPerLine && current.isNotEmpty) {
        lines.add(current);
        current = word;
      } else {
        current = candidate;
      }
    }
    if (current.isNotEmpty) lines.add(current);
  }
  return lines;
}
