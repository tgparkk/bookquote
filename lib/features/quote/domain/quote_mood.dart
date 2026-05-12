// 인용구 무드 태그.
//
// DB의 quotes.moods (text[])에는 enum name(영문)을 저장하고, 화면엔 label(한국어)을
// 보여준다. DB에 알 수 없는 값이 들어와도(앱 업데이트로 셋이 바뀐 경우 등) 파싱 시
// 조용히 무시한다 — 데이터 보존 (DECISIONS 2026-05-12, 시장 조사 차별화 ④).
//
// 작업 가정 셋: 위로 / 먹먹 / 새벽3시 / 통찰 / 설렘. 구현 전 최종 확정 가능.

enum QuoteMood {
  comfort('위로'),
  wistful('먹먹'),
  lateNight('새벽3시'),
  insight('통찰'),
  excitement('설렘');

  const QuoteMood(this.label);

  /// 화면에 표시할 한국어 라벨.
  final String label;

  /// 사용자가 한 인용구에 붙일 수 있는 최대 무드 수.
  static const int maxPerQuote = 3;

  /// enum name으로 역조회. 알 수 없는 이름이면 null.
  static QuoteMood? fromName(String name) {
    for (final m in QuoteMood.values) {
      if (m.name == name) return m;
    }
    return null;
  }
}
