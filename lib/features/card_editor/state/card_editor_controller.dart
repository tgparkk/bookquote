// 카드 에디터 controller. (`card-editor.md §4`, DECISIONS 2026-05-12)
//
// PR9 MVP 범위: templateId/ratio/watermarkEnabled 세 가지 상태만.
// PR12에서 paletteOverride/fontStep/textAnchor(상대좌표)/undoStack/redoStack 확장 예정.
//
// 영속화: `shared_preferences`에 `card-editor-draft:{quoteId}` 키로 저장.
// 사용자가 위젯을 만질 때마다 500ms 디버운스 persist. 인용구 본문은 DB에 있어
// 안전하지만 디자인 작업은 잃지 않도록(`card-editor.md §4 편집 상태 영속화`).
//
// quote는 한 화면에 한 건이라 controller 자체는 non-family. screen 진입 시
// `attach(quoteId)` 1회 호출로 영속화 키를 묶는다.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/tokens.dart';
import '../domain/card_template.dart';

@immutable
class CardEditorState {
  const CardEditorState({
    required this.templateId,
    required this.ratio,
    required this.watermarkEnabled,
  });

  final String templateId;
  final CardRatio ratio;
  final bool watermarkEnabled;

  /// 첫 진입 default — 사용자 인용구를 보기 전. screen이 데이터 도착 후
  /// `applyRecommended`로 갱신.
  static const CardEditorState initial = CardEditorState(
    templateId: 'minimal',
    ratio: CardRatio.story,
    watermarkEnabled: true,
  );

  CardEditorState copyWith({
    String? templateId,
    CardRatio? ratio,
    bool? watermarkEnabled,
  }) =>
      CardEditorState(
        templateId: templateId ?? this.templateId,
        ratio: ratio ?? this.ratio,
        watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'templateId': templateId,
        'ratio': ratio.name,
        'watermarkEnabled': watermarkEnabled,
      };

  factory CardEditorState.fromJson(Map<String, Object?> json) {
    final ratioName = json['ratio'] as String? ?? CardRatio.story.name;
    return CardEditorState(
      templateId: json['templateId'] as String? ?? 'minimal',
      ratio: CardRatio.values.firstWhere(
        (r) => r.name == ratioName,
        orElse: () => CardRatio.story,
      ),
      watermarkEnabled: json['watermarkEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardEditorState &&
          other.templateId == templateId &&
          other.ratio == ratio &&
          other.watermarkEnabled == watermarkEnabled;

  @override
  int get hashCode => Object.hash(templateId, ratio, watermarkEnabled);

  @override
  String toString() =>
      'CardEditorState($templateId, ${ratio.label}, wm:$watermarkEnabled)';
}

class CardEditorController extends Notifier<CardEditorState> {
  String? _quoteId;
  Timer? _persistTimer;

  @override
  CardEditorState build() {
    ref.onDispose(() {
      _persistTimer?.cancel();
    });
    return CardEditorState.initial;
  }

  /// screen 진입 시 1회 호출 — 영속화 키를 묶는다.
  void attach(String quoteId) {
    _quoteId = quoteId;
  }

  String? get _key => _quoteId == null ? null : 'card-editor-draft:$_quoteId';

  // ── 공개 API — 인터랙션 ────────────────────────────────────

  void setTemplate(String templateId) {
    if (state.templateId == templateId) return;
    state = state.copyWith(templateId: templateId);
    _persistDebounced();
  }

  void setRatio(CardRatio ratio) {
    if (state.ratio == ratio) return;
    state = state.copyWith(ratio: ratio);
    _persistDebounced();
  }

  void toggleWatermark() {
    state = state.copyWith(watermarkEnabled: !state.watermarkEnabled);
    _persistDebounced();
  }

  /// 인용구 길이·표지 유무로 추천 템플릿을 선택. data 도착 시 screen이 호출.
  void applyRecommended({required int charCount, required bool hasCover}) {
    final t = CardTemplate.recommended(charCount: charCount, hasCover: hasCover);
    if (state.templateId == t.id) return;
    state = state.copyWith(templateId: t.id);
    _persistDebounced();
  }

  /// 다음 템플릿으로 순환(`card-editor.md §4 "다른 느낌 ↻"`).
  /// 데이터 조건을 만족하지 않는 템플릿(T4 표지 없음 등)은 건너뛴다.
  void cycleTemplate({required int charCount, required bool hasCover}) {
    final all = CardTemplate.all;
    final currentIdx = all.indexWhere((t) => t.id == state.templateId);
    for (var i = 1; i <= all.length; i++) {
      final next = all[(currentIdx + i) % all.length];
      if (next.supports(charCount: charCount, hasCover: hasCover)) {
        setTemplate(next.id);
        return;
      }
    }
  }

  // ── 영속화 ────────────────────────────────────────────────

  /// "이어서 만들기" 다이얼로그가 호출. draft 없으면 null.
  Future<CardEditorState?> readDraft() async {
    final key = _key;
    if (key == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CardEditorState.fromJson(decoded);
    } catch (_) {
      // 손상된 draft는 무시 (다음 persist로 덮어씀)
      return null;
    }
  }

  /// 사용자가 "이어서 만들기"를 선택했을 때.
  /// 자체 persist는 트리거하지 않는다(복원은 새 편집 아님).
  void applyState(CardEditorState restored) {
    state = restored;
  }

  /// 사용자가 "새로 시작"을 선택했을 때, 또는 카드 공유 성공(PR10) 후.
  Future<void> clearDraft() async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  void _persistDebounced() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 500), _persist);
  }

  Future<void> _persist() async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(state.toJson()));
  }

  /// 테스트 hook — 타이머 기다리지 않고 즉시 저장.
  @visibleForTesting
  Future<void> debugFlushPersist() async {
    _persistTimer?.cancel();
    await _persist();
  }
}

final cardEditorControllerProvider =
    NotifierProvider.autoDispose<CardEditorController, CardEditorState>(
  CardEditorController.new,
);
