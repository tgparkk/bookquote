// 카드 골든 스냅샷 5종 × 3비율 = 15장 — PR12 부분(2026-05-16).
//
// 폰트 로드 보장: setUpAll에서 NotoSerifKR + Pretendard를 명시적으로 FontLoader로
// 등록. flutter_test 기본 환경은 Ahem 폰트라 텍스트가 사각형으로 렌더돼 골든이
// 무의미하므로 우리 번들 폰트를 강제 로드.
//
// surface size를 1080×{ratio} 절대 픽셀로 키워 카드 위젯 트리(`AppCardSize`)
// 그대로 캡처 — 실 export(PR10 `card_renderer`)와 픽셀 동일. ratio 별로
// 별도 surface size 적용.
//
// 회귀 안정성: OS/Flutter 엔진의 글리프 렌더링 차이로 픽셀이 달라질 수 있어
// 골든은 main에 push해두고 다른 환경에서 깨지면 `--update-goldens`로 재생성
// 후 commit하는 워크플로우. CI 도입 전엔 로컬에서만 비교.

import 'package:bookquote/core/theme/tokens.dart';
import 'package:bookquote/features/card_editor/domain/card_template.dart';
import 'package:bookquote/features/card_editor/domain/quote_card_data.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _longQuote = QuoteCardData(
  quoteText: '우리는 누군가의 가장 좋은 시절을 잘 모르는 채로도, 그 사람을 사랑할 수 있다.',
  bookTitle: '작별하지 않는다',
  bookAuthor: '한강',
  bookPublisher: '문학동네',
);

const _shortQuote = QuoteCardData(
  quoteText: '그래도 살아있다.',
  bookTitle: '미드나잇 라이브러리',
  bookAuthor: '매트 헤이그',
);

QuoteCardData _dataFor(CardTemplate t) =>
    t is TypographyTemplate ? _shortQuote : _longQuote;

Future<void> _loadFonts() async {
  Future<void> loadOne(String family, List<String> paths) async {
    final fl = FontLoader(family);
    for (final p in paths) {
      fl.addFont(rootBundle.load(p));
    }
    await fl.load();
  }

  await loadOne('NotoSerifKR', <String>[
    'assets/fonts/noto_serif_kr/NotoSerifKR-VariableFont_wght.ttf',
  ]);
  await loadOne('Pretendard', <String>[
    'assets/fonts/pretendard/Pretendard-Regular.otf',
    'assets/fonts/pretendard/Pretendard-Medium.otf',
    'assets/fonts/pretendard/Pretendard-SemiBold.otf',
  ]);
}

Widget _wrapCard(CardTemplate template, CardRatio ratio) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: AppColors.secondary300,
      body: Center(
        child: RepaintBoundary(
          child: QuoteCard(
            template: template,
            data: _dataFor(template),
            palette: QuoteCard.fallbackFor(template),
            ratio: ratio,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  // 5종 × 3비율 매트릭스. T4(CoverExtract)는 fallback 팔레트로 표지 없이도 렌더.
  // T5(Typography)는 단문 전용이라 _shortQuote만 사용.
  for (final t in CardTemplate.all) {
    for (final r in CardRatio.values) {
      // Typography는 cover 무관 + 단문 supports만, 그 외도 모두 supports OK.
      if (!t.supports(
        charCount: _dataFor(t).charCount,
        hasCover: _dataFor(t).hasCover,
      )) {
        continue;
      }
      testWidgets('${t.id} × ${r.label} 골든', (tester) async {
        final size = r.size;
        await tester.binding.setSurfaceSize(size);
        // 카드 자체가 절대 1080×N으로 build 되므로 surface=1080×N면 1:1 캡처.
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(_wrapCard(t, r));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(QuoteCard),
          matchesGoldenFile('golden/${t.id}_${r.name}.png'),
        );
      });
    }
  }
}
