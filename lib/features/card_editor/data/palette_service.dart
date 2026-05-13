// 표지 → ExtractedPalette 추출 서비스. `docs/design/color-extraction.md` §3·8 명세.
//
// - 메모리 LRU 캐시(키 = imageUrl). books 테이블에 색 컬럼을 추가하지 않는다
//   (클라이언트 캐시로 충분; 알라딘 CDN URL은 책 == 동일 URL이라 캐시 안전).
// - 추출 타임아웃 3초. 실패·null URL은 templateId별 fallback 팔레트로 폴백
//   (`color-extraction.md §9`).
// - 텍스트 색 슬롯(textOnBackground/subtextOnBackground)은 dominant 위에서
//   WCAG AA(4.5:1)·AA Large(3.0:1)를 만족하도록 ensureContrast로 자동 보장.

import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../core/theme/tokens.dart';
import 'color_utils.dart';

/// PaletteGenerator 생성 함수 시그니처. 테스트에서 fake로 주입한다.
typedef PaletteGeneratorFactory = Future<PaletteGenerator> Function(
  String imageUrl,
);

class PaletteService {
  PaletteService({
    PaletteGeneratorFactory? generatorFactory,
    int maxCacheSize = 100,
    Duration timeout = const Duration(seconds: 3),
  })  : _factory = generatorFactory ?? _defaultGeneratorFactory,
        _maxCacheSize = maxCacheSize,
        _timeout = timeout;

  final PaletteGeneratorFactory _factory;
  final int _maxCacheSize;
  final Duration _timeout;
  final LinkedHashMap<String, ExtractedPalette> _cache =
      LinkedHashMap<String, ExtractedPalette>();

  /// 표지 URL이 있으면 추출(캐시 hit이면 즉시), 없거나 실패하면 templateId
  /// 폴백 팔레트 반환. 항상 동기적으로 사용 가능한 값을 보장한다.
  Future<ExtractedPalette> getPaletteWithFallback(
    String? coverUrl,
    String templateId,
  ) async {
    final fallback =
        fallbackPalettes[templateId] ?? fallbackPalettes['minimal']!;
    if (coverUrl == null || coverUrl.isEmpty) return fallback;

    final cached = _cacheGet(coverUrl);
    if (cached != null) return cached;

    try {
      final generator = await _factory(coverUrl).timeout(_timeout);
      final palette = _toExtractedPalette(generator, fallback);
      _cachePut(coverUrl, palette);
      return palette;
    } catch (_) {
      return fallback;
    }
  }

  /// 캐시에서 키를 꺼내고 끝으로 다시 넣어 LRU 갱신.
  ExtractedPalette? _cacheGet(String key) {
    final v = _cache.remove(key);
    if (v == null) return null;
    _cache[key] = v;
    return v;
  }

  void _cachePut(String key, ExtractedPalette p) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first); // 가장 오래된 항목 제거
    }
    _cache[key] = p;
  }

  // 테스트 hook
  int get cacheSize => _cache.length;
  bool isCached(String key) => _cache.containsKey(key);
}

Future<PaletteGenerator> _defaultGeneratorFactory(String imageUrl) {
  return PaletteGenerator.fromImageProvider(
    CachedNetworkImageProvider(imageUrl),
    size: const Size(100, 100), // 다운스케일 — 성능 최적화
    maximumColorCount: 16,
  );
}

/// palette_generator 결과를 ExtractedPalette로 매핑. null 슬롯은 fallback 값으로.
ExtractedPalette _toExtractedPalette(
  PaletteGenerator gen,
  ExtractedPalette fallback,
) {
  final dominant = gen.dominantColor?.color ?? fallback.dominant;
  final secondary = gen.lightMutedColor?.color ?? fallback.secondary;
  final vibrant = gen.vibrantColor?.color ??
      gen.lightVibrantColor?.color ??
      fallback.vibrant;
  final darkVibrant = gen.darkVibrantColor?.color ?? fallback.darkVibrant;
  final muted =
      gen.mutedColor?.color ?? gen.darkMutedColor?.color ?? fallback.muted;

  final textOnBg = ensureContrast(
    dominant,
    _pickBestCandidate(dominant, const <Color>[
      AppColors.primary900,
      AppColors.secondary200,
    ]),
    minRatio: 4.5,
  );
  final subtextOnBg = ensureContrast(
    dominant,
    _pickBestCandidate(dominant, const <Color>[
      AppColors.primary700,
      AppColors.primary400,
      AppColors.secondary400,
    ]),
    minRatio: 3.0, // 보조 텍스트 = AA Large 기준
  );

  return ExtractedPalette(
    dominant: dominant,
    secondary: secondary,
    vibrant: vibrant,
    darkVibrant: darkVibrant,
    muted: muted,
    textOnBackground: textOnBg,
    subtextOnBackground: subtextOnBg,
  );
}

/// 후보 중 [background]와 대비비가 가장 높은 색을 고른다.
Color _pickBestCandidate(Color background, List<Color> candidates) {
  var best = candidates.first;
  var bestRatio = contrastRatio(background, best);
  for (var i = 1; i < candidates.length; i++) {
    final ratio = contrastRatio(background, candidates[i]);
    if (ratio > bestRatio) {
      best = candidates[i];
      bestRatio = ratio;
    }
  }
  return best;
}
