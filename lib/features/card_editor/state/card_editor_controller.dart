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
    this.fontStep = 0,
    this.undoDepth = 0,
  });

  final String templateId;
  final CardRatio ratio;
  final bool watermarkEnabled;

  /// 인용구 폰트 크기 미세조정 — `getQuoteFontSize(charCount)`에서 step×2px 가감.
  /// `[fontStepMin, fontStepMax]` 안에 clamp. 자동 계산이 기본(0)이며 사용자가
  /// [A−]/[A+]로 조정 가능. `templates/*.md §4 텍스트 ±` 명세.
  final int fontStep;

  /// 현재 controller `_undoStack`의 깊이를 mirror — UI가 `canUndo`로 ⤺ 버튼 활성을
  /// 결정한다. 영속화 대상 아님(재진입 시 stack 비어 있어 항상 0).
  final int undoDepth;

  bool get canUndo => undoDepth > 0;

  /// fontStep 가감 한계 — 명세 "보간 범위 안 ±2~3 step". V1은 ±3.
  static const int fontStepMin = -3;
  static const int fontStepMax = 3;

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
    int? fontStep,
    int? undoDepth,
  }) =>
      CardEditorState(
        templateId: templateId ?? this.templateId,
        ratio: ratio ?? this.ratio,
        watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
        fontStep: fontStep ?? this.fontStep,
        undoDepth: undoDepth ?? this.undoDepth,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'templateId': templateId,
        'ratio': ratio.name,
        'watermarkEnabled': watermarkEnabled,
        'fontStep': fontStep,
        // undoDepth는 영속화 안 함 — 재진입 시 stack은 비어 있음.
      };

  factory CardEditorState.fromJson(Map<String, Object?> json) {
    final ratioName = json['ratio'] as String? ?? CardRatio.story.name;
    final rawStep = (json['fontStep'] as num?)?.toInt() ?? 0;
    return CardEditorState(
      templateId: json['templateId'] as String? ?? 'minimal',
      ratio: CardRatio.values.firstWhere(
        (r) => r.name == ratioName,
        orElse: () => CardRatio.story,
      ),
      watermarkEnabled: json['watermarkEnabled'] as bool? ?? true,
      fontStep: rawStep.clamp(fontStepMin, fontStepMax),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardEditorState &&
          other.templateId == templateId &&
          other.ratio == ratio &&
          other.watermarkEnabled == watermarkEnabled &&
          other.fontStep == fontStep &&
          other.undoDepth == undoDepth;

  @override
  int get hashCode =>
      Object.hash(templateId, ratio, watermarkEnabled, fontStep, undoDepth);

  @override
  String toString() =>
      'CardEditorState($templateId, ${ratio.label}, wm:$watermarkEnabled, step:$fontStep, undo:$undoDepth)';
}

class CardEditorController extends Notifier<CardEditorState> {
  String? _quoteId;
  Timer? _persistTimer;
  // setter가 호출되는 시점에 캡처한 마지막 변경분(아직 IO로 안 나간). onDispose에서
  // state getter는 lifecycle 위반(Riverpod 3 assert)이므로 snapshot만 읽는다.
  CardEditorState? _pendingSnapshot;
  String? _pendingKey;

  /// 사용자의 명시적 변경(템플릿/비율/워터마크)을 push. ⤺ 언두로 되돌릴 대상.
  /// 자동 분기(applyRecommended)나 복원(applyState)은 푸시하지 않는다.
  /// 깊이 [_maxUndoDepth] 초과 시 가장 오래된 항목부터 제거.
  static const int _maxUndoDepth = 20;
  final List<CardEditorState> _undoStack = <CardEditorState>[];

  @override
  CardEditorState build() {
    ref.onDispose(() {
      // 사용자가 디자인 바꾼 직후 500ms 안에 화면을 나가면 디바운스 타이머가
      // 그대로 cancel되어 마지막 변경분이 영구 손실되던 문제(2026-05-16 실기기 발견).
      // 활성 타이머가 있으면 즉시 fire-and-forget으로 persist. SharedPreferences는
      // 글로벌 인스턴스라 화면이 사라져도 IO는 정상 완료된다.
      _persistTimer?.cancel();
      final s = _pendingSnapshot;
      final k = _pendingKey;
      _pendingSnapshot = null;
      _pendingKey = null;
      if (s != null && k != null) {
        unawaited(_persistRaw(k, s));
      }
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
    _pushUndo(state);
    state = state.copyWith(
      templateId: templateId,
      undoDepth: _undoStack.length,
    );
    _persistDebounced();
  }

  void setRatio(CardRatio ratio) {
    if (state.ratio == ratio) return;
    _pushUndo(state);
    state = state.copyWith(ratio: ratio, undoDepth: _undoStack.length);
    _persistDebounced();
  }

  void toggleWatermark() {
    _pushUndo(state);
    state = state.copyWith(
      watermarkEnabled: !state.watermarkEnabled,
      undoDepth: _undoStack.length,
    );
    _persistDebounced();
  }

  /// 폰트 step ±1. clamp 한계에 도달하면 no-op(언두 stack 노이즈 방지).
  /// 한 단계당 ~2px (위젯에서 step×2px 가감).
  void increaseFont() => _setFontStep(state.fontStep + 1);
  void decreaseFont() => _setFontStep(state.fontStep - 1);

  void _setFontStep(int next) {
    final clamped = next.clamp(
      CardEditorState.fontStepMin,
      CardEditorState.fontStepMax,
    );
    if (state.fontStep == clamped) return;
    _pushUndo(state);
    state = state.copyWith(fontStep: clamped, undoDepth: _undoStack.length);
    _persistDebounced();
  }

  /// 직전 변경(템플릿/비율/워터마크)을 되돌린다. 스택이 비면 no-op.
  /// redo는 V1.5 백로그.
  void undo() {
    if (_undoStack.isEmpty) return;
    final prev = _undoStack.removeLast();
    state = prev.copyWith(undoDepth: _undoStack.length);
    _persistDebounced();
  }

  void _pushUndo(CardEditorState snapshot) {
    // undoDepth 차이로 인한 노이즈 제거 — push 시점엔 stack 깊이만 다른 동일 상태
    // 비교를 위해 undoDepth: 0으로 정규화한 사본을 저장.
    _undoStack.add(snapshot.copyWith(undoDepth: 0));
    if (_undoStack.length > _maxUndoDepth) {
      _undoStack.removeAt(0);
    }
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
    _pendingSnapshot = state;
    _pendingKey = _key;
    _persistTimer = Timer(const Duration(milliseconds: 500), () {
      final s = _pendingSnapshot;
      final k = _pendingKey;
      _pendingSnapshot = null;
      _pendingKey = null;
      if (s != null && k != null) {
        unawaited(_persistRaw(k, s));
      }
    });
  }

  Future<void> _persist() async {
    final key = _key;
    if (key == null) return;
    await _persistRaw(key, state);
  }

  /// `state`와 `key`를 미리 받아 ref 없이 IO만 수행 — dispose 직후 fire-and-forget
  /// 경로(`ref.onDispose` → unawaited)에서도 안전.
  static Future<void> _persistRaw(String key, CardEditorState snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(snapshot.toJson()));
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
