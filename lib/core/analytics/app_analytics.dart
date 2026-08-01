// 책글귀 — 최소 행동 계측 (2026-08-01 출시 1개월 진단 W1).
//
// 이벤트 6종만 운영한다: app_open(GA4 자동 수집: first_open·session_start)
// + 아래 커스텀 5종. 퍼널: 설치 → 로그인 → (빈 홈) → 작성 진입 → 저장 → 공유.
//
// PII 금지 — 인용구 본문·검색어·이메일 등 raw 데이터는 절대 보내지 않는다
// (docs/design/screens/README.md 로깅 원칙: 코드·길이·화면명만).
//
// Firebase 미초기화 환경(위젯 테스트·웹)에선 조용히 no-op — 계측이 UX를
// 깨면 안 되므로 모든 실패를 삼킨다.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

const appAnalytics = AppAnalytics();

class AppAnalytics {
  const AppAnalytics();

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance
          .logEvent(name: name, parameters: params);
    } catch (_) {/* best-effort */}
  }

  /// 로그인 성공 — 로그인 벽 통과율. [provider]: 'google' | 'kakao'.
  Future<void> logLoginSuccess(String provider) =>
      _log('login_success', {'provider': provider});

  /// 빈 홈(인용구 0) 노출 — 활성화 대기 인원. 화면 인스턴스당 1회만 호출할 것.
  Future<void> logHomeEmptyView() => _log('home_empty_view');

  /// 인용구 작성 화면 진입 (신규 모드만).
  Future<void> logQuoteNewOpen({required bool hasBook}) =>
      _log('quote_new_open', {'has_book': hasBook ? 1 : 0});

  /// 인용구 저장 성공 — 활성화 완료. [offline]은 아웃박스 큐잉 케이스.
  Future<void> logQuoteSaveSuccess({
    required bool hasBook,
    required bool locked,
    required bool offline,
  }) =>
      _log('quote_save_success', {
        'has_book': hasBook ? 1 : 0,
        'locked': locked ? 1 : 0,
        'offline': offline ? 1 : 0,
      });

  /// 카드 공유 완료 — 바이럴 엔진 점화.
  /// [target]: 'kakao' | 'instagram' | 'save' | 'other'.
  Future<void> logCardShareSuccess(String target) =>
      _log('card_share_success', {'target': target});
}
