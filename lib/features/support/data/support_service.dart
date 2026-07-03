// 후원 IAP "차 한 잔" — 소모성 단일 상품 (수익모델 협의 2026-07-03).
//
// 기능 잠금 없음: 결제해도 앱은 그대로, 순수 후원. 소모성이라 복원·기기 간
// 동기화·서버 검증이 필요 없다(어뷰징 유인 낮음 — 협의 결론). Android는
// buyConsumable(autoConsume)로 소비까지 자동, pendingCompletePurchase만
// 방어적으로 마무리한다.
//
// Play Console 선행 조건: 결제 프로필 + 인앱 상품(`support_tea`, 소모성) 등록.
// 스토어 미설치/미등록 환경(사이드로드·에뮬레이터)에서는 loadProduct가 null을
// 돌려주고 시트가 안내 문구를 보여준다 — 크래시 금지.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Play Console 인앱 상품 ID (소모성).
const String kSupportTeaProductId = 'support_tea';

/// 구매 흐름의 UI 표시용 단계.
enum SupportPurchasePhase { pending, success, canceled, error }

class SupportService {
  SupportService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _phaseController = StreamController<SupportPurchasePhase>.broadcast();

  /// 구매 진행 상태 스트림 — 시트가 구독해 화면 상태를 전환한다.
  Stream<SupportPurchasePhase> get phases => _phaseController.stream;

  /// 스토어에서 후원 상품을 읽는다. 스토어 불가/미등록이면 null.
  Future<ProductDetails?> loadProduct() async {
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({kSupportTeaProductId});
      if (response.productDetails.isEmpty) return null;
      return response.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  /// 구매 시작. 결과는 [phases]로 도착한다. 시작 자체가 실패하면 false.
  Future<bool> buy(ProductDetails product) async {
    _sub ??= _iap.purchaseStream.listen(_onPurchaseUpdates);
    try {
      return await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      _phaseController.add(SupportPurchasePhase.error);
      return false;
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // 어떤 상태든 스토어가 마무리를 요구하면 응답 — 미완료 트랜잭션이
      // 다음 실행에서 재전달되는 것을 막는다.
      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (_) {/* 다음 purchaseStream 재전달에서 재시도됨 */}
      }
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _phaseController.add(SupportPurchasePhase.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _phaseController.add(SupportPurchasePhase.success);
        case PurchaseStatus.canceled:
          _phaseController.add(SupportPurchasePhase.canceled);
        case PurchaseStatus.error:
          _phaseController.add(SupportPurchasePhase.error);
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _phaseController.close();
  }
}

final supportServiceProvider = Provider<SupportService>((ref) {
  final service = SupportService();
  ref.onDispose(service.dispose);
  return service;
});
