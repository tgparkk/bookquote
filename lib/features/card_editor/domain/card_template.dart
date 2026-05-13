import 'package:flutter/foundation.dart';

/// 카드 템플릿 5종 — sealed 계열. `docs/design/templates/01~05.md` 명세 기반.
///
/// 각 템플릿은 메타데이터만 보유한 const 싱글톤이며, 실제 렌더는
/// `presentation/widgets/quote_card.dart`의 `QuoteCard` 디스패처가
/// 이 객체의 `runtimeType`을 보고 해당 위젯(`MinimalCard` 등)으로 라우팅한다.
///
/// 색 매핑(`colorMapping`)은 각 위젯 안에 helper로 둔다 — `ExtractedPalette` →
/// 템플릿별 색 슬롯 분배. 표지 fetch·팔레트 추출은 PR8(`palette_service.dart`)에서
/// 채워지며, PR7은 `fallbackPalettes[templateId]`만으로도 정상 렌더된다.
@immutable
sealed class CardTemplate {
  const CardTemplate();

  String get id;
  String get name;
  String get description;

  /// 이 템플릿이 주어진 인용구/책 조합에 적합한지.
  /// - T4 표지발췌: 표지가 없으면 `false`(`templates/04` 결정 — DECISIONS 2026-05-12)
  /// - T5 타이포: 51자 이상이면 `false`(`templates/05.maxCharCount`)
  /// - 그 외: 항상 `true`
  bool supports({required int charCount, required bool hasCover}) => true;

  /// 5종 const 싱글톤. 가로 한 줄 미리보기·이터레이션은 이 순서로.
  static const List<CardTemplate> all = <CardTemplate>[
    MinimalTemplate(),
    WarmTemplate(),
    MonoTemplate(),
    CoverExtractTemplate(),
    TypographyTemplate(),
  ];

  /// id 문자열로 템플릿 인스턴스 조회 (잘못된 id면 미니멀로 폴백)
  static CardTemplate byId(String id) => all.firstWhere(
        (t) => t.id == id,
        orElse: () => const MinimalTemplate(),
      );

  /// 인용구 길이·표지 유무로 추천 템플릿 1개를 고른다.
  /// `card-editor.md §4`의 간단 규칙. PR9 에디터 초기 진입 시 사용.
  static CardTemplate recommended({
    required int charCount,
    required bool hasCover,
  }) {
    if (charCount <= 30) return const TypographyTemplate();
    if (hasCover) return const CoverExtractTemplate();
    return const MinimalTemplate();
  }
}

/// T1 — 미니멀. 종이흰 배경, 인용구·구분선·책정보·워터마크.
final class MinimalTemplate extends CardTemplate {
  const MinimalTemplate();
  @override
  String get id => 'minimal';
  @override
  String get name => '미니멀';
  @override
  String get description => '흰 배경, 여백, 인용구 하나. 아무것도 더하지 않는다.';
}

/// T2 — 따뜻. 좌측 표지 패널 + 우측 크림 텍스트 패널(9:16/4:5),
/// 1:1은 상하 분할(Spotify 스타일).
final class WarmTemplate extends CardTemplate {
  const WarmTemplate();
  @override
  String get id => 'warm';
  @override
  String get name => '따뜻';
  @override
  String get description => '책 표지 옆에서 인용구가 숨 쉰다. 책을 펼쳐놓은 온기.';
}

/// T3 — 모노. 차콜(#0F0F0F) 고정 배경, 상하 1px 라인, 흰 세리프.
final class MonoTemplate extends CardTemplate {
  const MonoTemplate();
  @override
  String get id => 'mono';
  @override
  String get name => '모노';
  @override
  String get description => '어둠 속에서 문장 하나가 빛난다. 강렬하고 절제된 결.';
}

/// T4 — 표지 발췌. blur 표지 배경 + dominant overlay + 그라데이션 + 선명 표지 우하단.
/// 표지가 없는 책에서는 비활성화(썸네일에서 회색 + "표지가 필요해요" 오버레이).
final class CoverExtractTemplate extends CardTemplate {
  const CoverExtractTemplate();
  @override
  String get id => 'coverExtract';
  @override
  String get name => '표지 발췌';
  @override
  String get description => '표지 안으로 들어온다. 책의 색과 감정이 카드 전체를 채운다.';

  @override
  bool supports({required int charCount, required bool hasCover}) => hasCover;
}

/// T5 — 타이포. 시(詩) 배치, mid-tone 배경. 단문 전용(50자 이하).
final class TypographyTemplate extends CardTemplate {
  const TypographyTemplate();
  @override
  String get id => 'typography';
  @override
  String get name => '타이포';
  @override
  String get description => '문장이 시가 된다. 단문 전용. 텍스트가 조각처럼 공중에 뜬다.';

  /// `templates/05.md`의 단문 전용 상한
  static const int maxCharCount = 50;

  @override
  bool supports({required int charCount, required bool hasCover}) =>
      charCount <= maxCharCount;
}
