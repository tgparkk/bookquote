// cards 테이블 데이터 레이어 — Stage 3 PR11.
//
// 공유 성공 시 비차단으로 INSERT되는 immutable 공유 이력.
// V1엔 INSERT만. select/list는 V1.5 "내가 만든 카드 갤러리" 도입 시.
// RLS가 `auth.uid() = user_id`를 강제하므로 책 미연결(book_id null)도 OK.
//
// `recordShare`는 공유 시트가 떴을 때 fire-and-forget으로 호출된다 —
// 실패해도 공유 자체는 이미 OS 시트로 끝났으므로 silently swallow.
// 미로그인·Supabase 미초기화 환경에서는 no-op(release 환경 누락 방지).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../state/card_editor_controller.dart';

class CardRepository {
  CardRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'cards';

  /// 공유 성공 시 비차단 INSERT. 호출자는 await 안 해도 되고, 예외도 안 던진다.
  /// `quoteId`는 RLS 정합용 필수. `bookId`는 책 미연결이면 null.
  /// `design`은 [`CardEditorState`]를 그대로 jsonb로 넘긴다 — `toJson` 스키마가
  /// design jsonb 페이로드 그 자체.
  Future<void> recordShare({
    required String quoteId,
    String? bookId,
    required CardEditorState design,
  }) async {
    if (!isSupabaseReady) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from(_table).insert(<String, dynamic>{
        'user_id': uid,
        'quote_id': quoteId,
        'book_id': bookId,
        'design': design.toJson(),
      });
    } catch (_) {
      // 비차단 — 공유는 이미 OS 시트로 끝났다. 이력 기록 실패는 사용자에게 무관.
      // V1은 silently swallow. 향후 분석 손실이 크면 retry 큐 도입.
    }
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(supabase);
});
