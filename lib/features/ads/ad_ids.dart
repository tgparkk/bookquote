// AdMob 광고 단위 ID (수익모델 확정 2026-07-03).
//
// debug 빌드는 항상 Google 공식 테스트 배너를 쓴다 — 개발 중 실 광고를
// 노출·클릭하면 무효 트래픽으로 계정 정지 사유가 된다(재정지 전적 주의).
// release만 실제 광고 단위를 쓴다. 본인 실기기 검증 시 실 광고를 클릭하지
// 말 것 — AdMob 콘솔 > 설정 > 테스트 기기 등록 권장.
// 앱 ID(~1381070822)는 AndroidManifest.xml의 APPLICATION_ID meta-data.

import 'package:flutter/foundation.dart' show kDebugMode;

const String _prodHomeBannerAdUnitId =
    'ca-app-pub-7230084799824817/7141462724'; // home_bottom_banner

// TODO: AdMob 콘솔에서 `me_bottom_banner` 배너 단위 발급 후 채우기 —
// 비어 있는 동안은 홈 단위로 서빙된다(수익 동일, 리포트만 합산).
const String _prodMeBannerAdUnitId = '';

const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

String get homeBannerAdUnitId =>
    kDebugMode ? _testBannerAdUnitId : _prodHomeBannerAdUnitId;

String get meBannerAdUnitId => kDebugMode
    ? _testBannerAdUnitId
    : (_prodMeBannerAdUnitId.isEmpty
        ? _prodHomeBannerAdUnitId
        : _prodMeBannerAdUnitId);
