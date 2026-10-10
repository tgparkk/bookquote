// 공유 카드(1080 폭 캔버스) 인용구 타이포그래피.
//
// 앱 화면용 `getQuoteFontSize`(tokens.dart)와 분리한다. 그 값(21~28px)은
// 휴대폰 화면(~360dp) 기준인데 카드 캔버스는 1080px이라, 그대로 쓰면 인용구가
// 가로폭의 3% 크기로 책 제목(36px)보다 작게 나왔다(2026-10-10 점검). 목업
// (225px 폭 카드에 인용구 13~14.5px ≈ 폭의 6%)을 1080으로 환산한 값이 기준.
//
// 실제 렌더 크기는 [CardQuoteText]가 이 목표값에서 시작해 주어진 영역에 들어갈
// 때까지 줄인다 — 짧은 글은 크게, 긴 글은 영역 안에서 최대한 크게.

/// 글자 수 → 목표 크기 기준점(px, 1080 캔버스). 사이는 선형 보간.
const List<(int, double)> _sizeCurve = <(int, double)>[
  (50, 64),
  (120, 54),
  (200, 48),
  (350, 42),
  (500, 38),
  (800, 34),
];

/// [A−]/[A+] 한 단계당 가감(px).
const double cardQuoteStepPx = 4;

/// 영역 맞춤으로 줄일 수 있는 하한. 이 아래로는 줄이지 않고 말줄임 처리.
const double cardQuoteMinSize = 28;

/// 목표 크기 상한([A+] 최대).
const double cardQuoteMaxSize = 84;

/// 글자 수와 사용자 단계(±3)로 정한 인용구 목표 크기.
double cardQuoteTargetSize(int charCount, int fontStep) {
  final double base;
  if (charCount <= _sizeCurve.first.$1) {
    base = _sizeCurve.first.$2;
  } else if (charCount >= _sizeCurve.last.$1) {
    base = _sizeCurve.last.$2;
  } else {
    var b = _sizeCurve.last.$2;
    for (var i = 0; i < _sizeCurve.length - 1; i++) {
      final (c0, s0) = _sizeCurve[i];
      final (c1, s1) = _sizeCurve[i + 1];
      if (charCount <= c1) {
        b = s0 + (s1 - s0) * (charCount - c0) / (c1 - c0);
        break;
      }
    }
    base = b;
  }
  return (base + fontStep * cardQuoteStepPx)
      .clamp(cardQuoteMinSize, cardQuoteMaxSize);
}

/// 크기별 행간 배율 — 큰 글씨일수록 좁게(32px 1.7 → 64px 1.5).
double cardQuoteLineHeight(double fontSize) {
  const lo = 32.0, hi = 64.0;
  final t = ((fontSize - lo) / (hi - lo)).clamp(0.0, 1.0);
  return 1.7 - 0.2 * t;
}
