// 책 표지 위젯.
//
// `cached_network_image`로 디스크·메모리 캐시. 표지 URL 누락·로드 실패 시
// 베이지 placeholder + 책 제목 첫 글자로 폴백 (디자인 일원화).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    required this.title,
    this.width = 56,
    this.height = 80,
    this.borderRadius,
  });

  final String? url;
  final String title;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sm);
    final src = url?.trim();

    if (src == null || src.isEmpty) {
      return _Placeholder(
        title: title,
        width: width,
        height: height,
        borderRadius: radius,
      );
    }

    // 표지를 표시 크기에 맞춰 디코딩 — memCacheWidth가 없으면 표지를 원본
    // 해상도로 디코딩해 ImageCache(기본 100MB)에 누적, 저사양폰 메모리를
    // 압박한다(B9). 단계값으로 양자화해 비슷한 크기 호출처가 캐시 엔트리를
    // 공유하게 한다. export는 toImage 별도 경로라 영향 없음.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memWidth = _decodeWidthFor(width * dpr);

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        memCacheWidth: memWidth,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, _) => _Placeholder(
          title: title,
          width: width,
          height: height,
          borderRadius: BorderRadius.zero,
        ),
        errorWidget: (_, _, _) => _Placeholder(
          title: title,
          width: width,
          height: height,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

/// 표지 디코딩 폭을 단계값(256/512/1280)으로 양자화. 비슷한 크기의 호출처가
/// 같은 ImageCache 엔트리를 공유하게 해 표지 비트맵 메모리 누적을 줄인다.
int _decodeWidthFor(double neededPx) {
  if (neededPx <= 256) return 256;
  if (neededPx <= 512) return 512;
  return 1280;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.title,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final String title;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final initial = title.isEmpty ? '?' : title.characters.first;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondary400,
        borderRadius: borderRadius,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: AppFonts.quote,
          fontWeight: FontWeight.w500,
          fontSize: width * 0.5,
          color: AppColors.primary700,
        ),
      ),
    );
  }
}
