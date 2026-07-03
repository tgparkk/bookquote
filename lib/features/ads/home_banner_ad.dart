// 홈 하단 고정 배너 (anchored adaptive) — 수익모델 확정 2026-07-03.
//
// 홈 Scaffold의 bottomNavigationBar 슬롯에 들어간다: 피드와 BottomNav 사이,
// FAB는 Scaffold가 배너 위로 자동으로 띄워줘 우발 클릭 겹침이 없다.
// 로드 실패·미지원 플랫폼(웹/데스크톱/테스트)에서는 SizedBox.shrink로
// 자리 자체를 차지하지 않는다 — 광고가 안 나와도 화면은 평소와 동일.

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

class HomeBannerAd extends StatefulWidget {
  const HomeBannerAd({super.key});

  @override
  State<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<HomeBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // 크기 계산에 MediaQuery 폭이 필요해 첫 프레임 이후로 미룬다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    final orientation = MediaQuery.orientationOf(context);
    try {
      // v9가 권장하는 large 변형(getLargeAnchoredAdaptiveBannerAdSize...)은
      // 화면 높이 최대 15%까지 커진다 — "작은 광고" 방침이라 기존 anchored
      // adaptive(최대 ~90dp)를 유지한다.
      final size =
          // ignore: deprecated_member_use
          await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width);
      if (size == null || !mounted) return;
      final ad = BannerAd(
        adUnitId: homeBannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) => ad.dispose(), // 실패 시 자리 차지 X
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      // 플러그인 미지원 환경(위젯 테스트 등) — 배너 없이 조용히 지나간다.
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
