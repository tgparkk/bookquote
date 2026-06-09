// LikeCount 낙관적 토글 헬퍼 순수 로직 테스트 (PR-LB).
// RLS·네트워크는 pgTAP(rls_likes.test.sql)이 커버 — 여기선 클라 낙관 전이만.

import 'package:bookquote/features/likes/data/like_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LikeCount.toggled', () {
    test('안 누름 → 누름: n+1, likedByMe=true', () {
      const before = (n: 3, likedByMe: false);
      final after = before.toggled;
      expect(after.n, 4);
      expect(after.likedByMe, true);
    });

    test('누름 → 취소: n-1, likedByMe=false', () {
      const before = (n: 3, likedByMe: true);
      final after = before.toggled;
      expect(after.n, 2);
      expect(after.likedByMe, false);
    });

    test('취소 시 0 미만으로 내려가지 않음', () {
      const before = (n: 0, likedByMe: true);
      final after = before.toggled;
      expect(after.n, 0);
      expect(after.likedByMe, false);
    });

    test('두 번 토글하면 원상복구', () {
      const before = (n: 5, likedByMe: false);
      expect(before.toggled.toggled, before);
    });

    test('kEmptyLikeCount 기본값', () {
      expect(kEmptyLikeCount.n, 0);
      expect(kEmptyLikeCount.likedByMe, false);
    });
  });
}
