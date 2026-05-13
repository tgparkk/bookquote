// PaletteService LRU 캐시 + URL/오류 폴백 경로.

import 'package:bookquote/core/theme/tokens.dart';
import 'package:bookquote/features/card_editor/data/palette_service.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette_generator/palette_generator.dart';

/// 테스트용 fake — 미리 정한 색 한 가지를 dominantPaletteColor로 보고하는 generator.
Future<PaletteGenerator> _fakeFactory(Color color) async =>
    PaletteGenerator.fromColors(<PaletteColor>[PaletteColor(color, 1000)]);

void main() {
  group('URL 없음/빈 문자열', () {
    test('null URL → templateId 폴백', () async {
      final svc = PaletteService();
      final p = await svc.getPaletteWithFallback(null, 'minimal');
      expect(p.dominant, fallbackPalettes['minimal']!.dominant);
      expect(svc.cacheSize, 0);
    });

    test('빈 문자열 URL → templateId 폴백', () async {
      final svc = PaletteService();
      final p = await svc.getPaletteWithFallback('', 'mono');
      expect(p.dominant, fallbackPalettes['mono']!.dominant);
    });

    test('모르는 templateId → minimal 폴백', () async {
      final svc = PaletteService();
      final p = await svc.getPaletteWithFallback(null, 'unknown-id');
      expect(p.dominant, fallbackPalettes['minimal']!.dominant);
    });
  });

  group('factory 오류 경로', () {
    test('throw하면 templateId 폴백 + 캐시 미저장', () async {
      final svc = PaletteService(
        generatorFactory: (_) => Future<PaletteGenerator>.error(
          Exception('boom'),
        ),
      );
      final p = await svc.getPaletteWithFallback(
        'http://example.com/a.jpg',
        'minimal',
      );
      expect(p.dominant, fallbackPalettes['minimal']!.dominant);
      expect(svc.cacheSize, 0);
    });

    test('타임아웃 → 폴백', () async {
      final svc = PaletteService(
        generatorFactory: (_) async {
          await Future<void>.delayed(const Duration(seconds: 10));
          return _fakeFactory(const Color(0xFFFF0000));
        },
        timeout: const Duration(milliseconds: 50),
      );
      final p = await svc.getPaletteWithFallback(
        'http://example.com/a.jpg',
        'minimal',
      );
      expect(p.dominant, fallbackPalettes['minimal']!.dominant);
    });
  });

  group('LRU 캐시', () {
    test('성공 결과는 캐시되고 두 번째 호출은 factory 미호출', () async {
      var calls = 0;
      final svc = PaletteService(
        generatorFactory: (_) {
          calls++;
          return _fakeFactory(const Color(0xFFFF0000));
        },
      );
      await svc.getPaletteWithFallback('http://example.com/a.jpg', 'minimal');
      await svc.getPaletteWithFallback('http://example.com/a.jpg', 'minimal');
      expect(calls, 1);
      expect(svc.cacheSize, 1);
      expect(svc.isCached('http://example.com/a.jpg'), isTrue);
    });

    test('maxCacheSize=2 — 3번째 put이 가장 오래된 항목 evict', () async {
      final svc = PaletteService(
        generatorFactory: (_) => _fakeFactory(const Color(0xFFFF0000)),
        maxCacheSize: 2,
      );
      await svc.getPaletteWithFallback('a', 'minimal');
      await svc.getPaletteWithFallback('b', 'minimal');
      await svc.getPaletteWithFallback('c', 'minimal');
      expect(svc.isCached('a'), isFalse);
      expect(svc.isCached('b'), isTrue);
      expect(svc.isCached('c'), isTrue);
      expect(svc.cacheSize, 2);
    });

    test('LRU touch — get으로 a 다시 사용하면 b가 더 오래된 것이 됨', () async {
      final svc = PaletteService(
        generatorFactory: (_) => _fakeFactory(const Color(0xFFFF0000)),
        maxCacheSize: 2,
      );
      await svc.getPaletteWithFallback('a', 'minimal');
      await svc.getPaletteWithFallback('b', 'minimal');
      // a 다시 호출 → cache hit, LRU 끝으로 이동
      await svc.getPaletteWithFallback('a', 'minimal');
      // c 추가 → 이제 b가 가장 오래된 → evict
      await svc.getPaletteWithFallback('c', 'minimal');
      expect(svc.isCached('a'), isTrue);
      expect(svc.isCached('b'), isFalse);
      expect(svc.isCached('c'), isTrue);
    });
  });
}
