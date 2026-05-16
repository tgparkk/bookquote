// CardShareException — 메시지 포맷·toString 계약.
// shareCardImage 자체의 실 호출은 플랫폼 채널 의존이라 V1엔 안 한다.

import 'package:bookquote/features/card_editor/data/share_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardShareException', () {
    test('toString은 prefix와 message 포함', () {
      const e = CardShareException('실패 사유');
      expect(e.toString(), 'CardShareException: 실패 사유');
    });

    test('Exception 계약을 따른다', () {
      const Object e = CardShareException('x');
      expect(e, isA<Exception>());
    });
  });
}
