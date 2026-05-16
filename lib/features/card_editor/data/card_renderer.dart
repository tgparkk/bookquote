// 카드 PNG 렌더러 — Stage 3 PR10.
//
// 화면에 떠 있는 카드 미리보기(`RepaintBoundary`)를 1080 폭 PNG로 캡처해 임시
// 파일로 저장한다. 미리보기는 `FittedBox`로 축소되어 있지만, 위젯 트리 자체는
// `AppCardSize[ratio]` 절대 픽셀로 build 되므로 캡처 시 `pixelRatio =
// targetWidth / boundary.size.width` 보정만 하면 명세 해상도가 나온다.
// "미리보기 = export" 원칙(`presentation/widgets/quote_card.dart` 참고).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/tokens.dart';

class CardRenderException implements Exception {
  const CardRenderException(this.message);
  final String message;
  @override
  String toString() => 'CardRenderException: $message';
}

/// 캡처 가능한 `RenderRepaintBoundary`를 가진 `GlobalKey`를 받아
/// PNG 임시 파일로 직렬화한 `XFile`을 반환한다.
///
/// `pixelRatio`는 `AppCardSize[ratio].width / boundary.size.width`로 계산되어,
/// 화면 크기와 무관하게 출력은 항상 1080×{1920|1080|1350} 픽셀.
Future<XFile> renderCardPng({
  required GlobalKey boundaryKey,
  required CardRatio ratio,
}) async {
  final boundary = _resolveBoundary(boundaryKey);
  await _waitForReadyFrame(boundary);

  final displayWidth = boundary.size.width;
  if (displayWidth <= 0) {
    throw const CardRenderException('boundary has zero width');
  }
  final pixelRatio = ratio.size.width / displayWidth;

  ui.Image? image;
  try {
    image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw const CardRenderException('failed to encode PNG');
    }
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/bookquote-card-$ts.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    return XFile(
      file.path,
      mimeType: 'image/png',
      name: 'bookquote-card.png',
    );
  } finally {
    image?.dispose();
  }
}

RenderRepaintBoundary _resolveBoundary(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) {
    throw const CardRenderException('boundary context is null');
  }
  final render = ctx.findRenderObject();
  if (render is! RenderRepaintBoundary) {
    throw const CardRenderException(
      'render object is not a RepaintBoundary',
    );
  }
  return render;
}

/// 폰트 atlas가 GPU에 올라온 뒤 다음 프레임이 그려질 때까지 기다린다.
/// endOfFrame 2회로 첫 layout/paint + 폰트 적용까지 안전망. `debugNeedsPaint`는
/// release 빌드에서 LateInitializationError를 던지므로 사용 금지(assert로 stripping됨).
Future<void> _waitForReadyFrame(RenderRepaintBoundary boundary) async {
  await WidgetsBinding.instance.endOfFrame;
  await WidgetsBinding.instance.endOfFrame;
}
