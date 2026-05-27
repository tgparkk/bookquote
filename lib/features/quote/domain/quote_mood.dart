// 인용구 무드 태그.
//
// DB의 quotes.moods (text[])에는 enum name(영문)을 저장하고, 화면엔 label(한국어)을
// 보여준다. DB에 알 수 없는 값이 들어와도(앱 업데이트로 셋이 바뀐 경우 등) 파싱 시
// 조용히 무시한다 — 데이터 보존 (DECISIONS 2026-05-12, 시장 조사 차별화 ④).
//
// 작업 가정 셋: 위로 / 먹먹 / 새벽3시 / 통찰 / 설렘. 구현 전 최종 확정 가능.

import 'package:flutter/material.dart';

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

/// 무드 표시 메타데이터 단일 정의처.
///
/// 라벨(`QuoteMood.label`) · 컬러(`mood_chips.dart`의 `moodColorOf`) · 아이콘 ·
/// tagline. 이전엔 아이콘이 `mood_hub_grid.dart`의 private `_iconFor`에 있어
/// 같은 무드를 다른 화면에서 쓸 때 동기화가 필요했다. 모든 메타가 enum을 진입점으로.
extension QuoteMoodPresentation on QuoteMood {
  /// hub 카드 라벨 옆에 1줄로 보여주는 "어떤 기분일 때 모은 글인지" 안내.
  /// "위로" 한 단어로 모드의 정체성이 와닿지 않는다는 피드백(PR29) 해결용.
  String get tagline => switch (this) {
        QuoteMood.comfort => '마음이 무거울 때',
        QuoteMood.wistful => '먹먹하게 남은 문장',
        QuoteMood.lateNight => '잠 못 드는 새벽',
        QuoteMood.insight => '머릿속이 환해진 순간',
        QuoteMood.excitement => '심장이 뛰던 페이지',
      };

  /// 무드 hub 카드 · 필터 · 카드 에디터 등에서 공통으로 쓰는 아이콘.
  IconData get icon => switch (this) {
        QuoteMood.comfort => Icons.favorite_outline_rounded,
        QuoteMood.wistful => Icons.cloud_outlined,
        QuoteMood.lateNight => Icons.nightlight_outlined,
        QuoteMood.insight => Icons.lightbulb_outline_rounded,
        QuoteMood.excitement => Icons.auto_awesome_outlined,
      };
}
