// 공유 캡처 직전 대기 — 카드가 비동기로 받는 입력이 모두 준비된 뒤에 찍는다.
//
// '바로 공유'는 화면 진입 2프레임 뒤 바로 캡처해서, 표지 이미지(다운로드 중 →
// 첫 글자 placeholder)·blur 배경(단색)·프로필 닉네임(기본 9px 워터마크)이 빠진
// PNG가 공유됐다(2026-10-10 실기기, 카카오톡 수신 화면에서 확인).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../domain/quote_card_data.dart';
import '../presentation/widgets/card_cover_image.dart';
import 'palette_providers.dart';

/// 입력 대기 상한 — 네트워크가 느려도 공유 자체는 막지 않는다.
const Duration _inputsTimeout = Duration(seconds: 6);

/// 에디터 미리보기의 템플릿·닉네임 전환 AnimatedSwitcher(200ms)가 끝나기를
/// 기다리는 여유 — 교차 페이드 중간(반투명)이 찍히지 않게.
const Duration _settleDelay = Duration(milliseconds: 250);

Future<void> waitForCardInputs(
  BuildContext context,
  WidgetRef ref, {
  required QuoteCardData data,
  required String templateId,
}) async {
  Future<void> quietly(Future<Object?> f) => f.then((_) {}, onError: (_) {});

  await Future.wait<void>([
    precacheCardImages(context, data.coverUrl),
    quietly(ref.read(extractedPaletteProvider(
      (coverUrl: data.coverUrl, templateId: templateId),
    ).future)),
    quietly(ref.read(myProfileProvider.future)),
  ]).timeout(_inputsTimeout, onTimeout: () => const []);

  await Future<void>.delayed(_settleDelay);
  // 준비된 값으로 다시 그린 프레임이 RepaintBoundary에 반영되도록.
  await WidgetsBinding.instance.endOfFrame;
  await WidgetsBinding.instance.endOfFrame;
}
