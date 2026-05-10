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

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: BoxFit.cover,
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
