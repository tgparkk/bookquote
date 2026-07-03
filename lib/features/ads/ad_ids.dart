// AdMob 광고 단위 ID (홈 하단 배너 — 수익모델 확정 2026-07-03).
//
// TODO(프로덕션 승격 전): AdMob 콘솔에서 앱 + 배너 광고 단위를 만들고
// `_prodHomeBannerAdUnitId`를 실제 값으로 교체할 것. AndroidManifest.xml의
// APPLICATION_ID(현재 테스트 앱 ID)도 함께 교체.
//
// 실제 ID가 채워지기 전까지는 debug/release 모두 Google 공식 테스트 배너를
// 쓴다 — 테스트 광고는 정책 위반 없이 실기기 검증이 가능하고, 실 광고 ID를
// 개발 중에 쓰면 무효 트래픽으로 계정 정지 사유가 된다(재정지 전적 주의).

const String _prodHomeBannerAdUnitId = ''; // 미발급 — 발급 후 채우기
const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

String get homeBannerAdUnitId =>
    _prodHomeBannerAdUnitId.isEmpty ? _testBannerAdUnitId : _prodHomeBannerAdUnitId;
