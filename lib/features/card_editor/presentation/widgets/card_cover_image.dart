import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../book/presentation/widgets/book_cover.dart';

// 카드 템플릿 전용 표지 이미지.
//
// 앱 화면용 `BookCover`(CachedNetworkImage + 페이드인)를 카드에 그대로 쓰면
// '바로 공유'처럼 진입 직후 캡처할 때 표지가 아직 내려받는 중이라 첫 글자
// placeholder가 PNG에 찍혔다(2026-10-10 실기기). 카드는 provider를 고정해 두고
// 캡처 전에 [precacheCardImages]로 같은 provider를 미리 디코드한다 — 그러면
// ImageCache에서 첫 프레임에 동기로 그려지고, 페이드인도 없다.

/// 선명 표지(카드 캔버스 최대 360px 폭)용 디코드 폭.
const int _sharpDecodeWidth = 512;

/// 표지 발췌 blur 배경용 디코드 폭 — 인쇄 요소를 미리 뭉개는 저해상도.
const int _backdropDecodeWidth = 16;

ImageProvider cardSharpCoverProvider(String url) =>
    ResizeImage(CachedNetworkImageProvider(url), width: _sharpDecodeWidth);

ImageProvider cardBackdropProvider(String url) =>
    ResizeImage(CachedNetworkImageProvider(url), width: _backdropDecodeWidth);

/// 카드에 들어가는 표지 이미지를 미리 받아 디코드. 실패·지연은 삼킨다 —
/// 표지 없이라도 공유는 되어야 하므로(placeholder로 그려짐).
Future<void> precacheCardImages(BuildContext context, String? coverUrl) async {
  final url = coverUrl?.trim();
  if (url == null || url.isEmpty) return;
  await Future.wait<void>([
    precacheImage(cardSharpCoverProvider(url), context, onError: (_, _) {}),
    precacheImage(cardBackdropProvider(url), context, onError: (_, _) {}),
  ]);
}

/// 카드용 선명 표지. 로딩 중·실패·URL 없음은 `BookCover`와 같은 첫 글자 placeholder.
class CardCoverImage extends StatelessWidget {
  const CardCoverImage({
    super.key,
    required this.url,
    required this.title,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final String? url;
  final String title;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final src = url?.trim();
    final placeholder = BookCover(
      url: null,
      title: title,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
    if (src == null || src.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image(
        image: cardSharpCoverProvider(src),
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        frameBuilder: (_, child, frame, wasSync) =>
            frame == null && !wasSync ? placeholder : child,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

/// 표지 발췌 배경 — 저해상도 표지. 로딩 중·실패는 [fallback] 단색.
class CardBackdropImage extends StatelessWidget {
  const CardBackdropImage({
    super.key,
    required this.url,
    required this.fallback,
  });

  final String url;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: fallback);
    return Image(
      image: cardBackdropProvider(url),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (_, child, frame, wasSync) =>
          frame == null && !wasSync ? placeholder : child,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
