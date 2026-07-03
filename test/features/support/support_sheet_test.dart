// 후원 시트 — fake SupportService로 구매 흐름 상태 전환을 검증한다.
// 실제 스토어(in_app_purchase 플랫폼 채널)는 테스트에서 호출되지 않는다.

import 'dart:async';

import 'package:bookquote/features/support/data/support_service.dart';
import 'package:bookquote/features/support/presentation/support_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _FakeSupportService implements SupportService {
  _FakeSupportService({this.product});

  final ProductDetails? product;
  final phaseController = StreamController<SupportPurchasePhase>.broadcast();
  int buyCalls = 0;

  @override
  Stream<SupportPurchasePhase> get phases => phaseController.stream;

  @override
  Future<ProductDetails?> loadProduct() async => product;

  @override
  Future<bool> buy(ProductDetails product) async {
    buyCalls++;
    return true;
  }

  @override
  void dispose() {
    phaseController.close();
  }
}

ProductDetails _teaProduct() => ProductDetails(
      id: kSupportTeaProductId,
      title: '차 한 잔',
      description: '개발자에게 차 한 잔을 건넵니다.',
      price: '₩3,300',
      rawPrice: 3300,
      currencyCode: 'KRW',
    );

Future<void> _pumpAndOpenSheet(
  WidgetTester tester,
  _FakeSupportService service,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supportServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showSupportSheet(context),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('상품 로드 성공 — 후원 카피와 가격 버튼이 보인다', (tester) async {
    final service = _FakeSupportService(product: _teaProduct());
    addTearDown(service.dispose);
    await _pumpAndOpenSheet(tester, service);

    expect(find.textContaining('차 한 잔 건네주세요'), findsOneWidget);
    expect(find.text('차 한 잔 건네기 · ₩3,300'), findsOneWidget);
  });

  testWidgets('구매 성공 — buy 호출 후 success phase에 감사 화면 전환', (tester) async {
    final service = _FakeSupportService(product: _teaProduct());
    addTearDown(service.dispose);
    await _pumpAndOpenSheet(tester, service);

    await tester.tap(find.text('차 한 잔 건네기 · ₩3,300'));
    await tester.pump();
    expect(service.buyCalls, 1);

    service.phaseController.add(SupportPurchasePhase.success);
    await tester.pumpAndSettle();
    expect(find.text('따뜻한 차, 잘 받았어요.'), findsOneWidget);

    // [닫기]로 시트가 닫힌다.
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('따뜻한 차, 잘 받았어요.'), findsNothing);
  });

  testWidgets('구매 취소 — 조용히 원래 화면으로 복귀', (tester) async {
    final service = _FakeSupportService(product: _teaProduct());
    addTearDown(service.dispose);
    await _pumpAndOpenSheet(tester, service);

    await tester.tap(find.text('차 한 잔 건네기 · ₩3,300'));
    await tester.pump();
    service.phaseController.add(SupportPurchasePhase.canceled);
    await tester.pumpAndSettle();

    expect(find.text('차 한 잔 건네기 · ₩3,300'), findsOneWidget);
  });

  testWidgets('스토어 불가 — 안내 문구만 보이고 버튼 없음', (tester) async {
    final service = _FakeSupportService(product: null);
    addTearDown(service.dispose);
    await _pumpAndOpenSheet(tester, service);

    expect(find.text('지금은 스토어에 연결할 수 없어요'), findsOneWidget);
    expect(find.textContaining('차 한 잔 건네기 ·'), findsNothing);
  });
}
