// 표지 → 추출 팔레트 providers. (`docs/design/color-extraction.md` §10)
//
// `PaletteService`는 LRU 캐시를 보유하므로 앱 수명 동안 단일 인스턴스(Provider scope).
// `extractedPaletteProvider`는 family — (coverUrl, templateId) 쌍을 키로 한다.
// templateId는 추출 실패/null URL 시 사용되는 폴백 팔레트 선택에만 영향.
// 같은 coverUrl이면 templateId가 달라도 service의 캐시는 hit한다(키는 URL).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../data/palette_service.dart';

final paletteServiceProvider =
    Provider<PaletteService>((ref) => PaletteService());

/// (coverUrl, templateId) 쌍. Dart 3 record라 value equality·hashable —
/// Riverpod family 키로 안전하게 사용.
typedef PaletteRequest = ({String? coverUrl, String templateId});

final extractedPaletteProvider = FutureProvider.autoDispose
    .family<ExtractedPalette, PaletteRequest>((ref, req) async {
  final service = ref.read(paletteServiceProvider);
  return service.getPaletteWithFallback(req.coverUrl, req.templateId);
});
