// 알림 도메인 모델 (PR-NB).
// `my_notifications` RPC 한 행과 1:1. 인용구·후기 좋아요/팔로우 알림 공용.
// 코드젠 없이 plain class + fromRow (RPC 투영이라 freezed 불필요).

enum NotificationType {
  quoteLike,
  reviewLike,
  follow,
  unknown;

  static NotificationType fromName(String? name) => switch (name) {
        'quote_like' => quoteLike,
        'review_like' => reviewLike,
        'follow' => follow,
        _ => unknown,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.createdAt,
    this.actorDisplayName,
    this.actorAvatarUrl,
    this.quoteId,
    this.reviewId,
    this.targetBookId,
    this.preview,
    this.readAt,
  });

  final String id;
  final NotificationType type;
  final String actorId;

  /// 비공개/차단 actor는 RPC가 null로 내려보냄(익명). null이면 '누군가'로 표시.
  final String? actorDisplayName;
  final String? actorAvatarUrl;

  /// 대상 식별 — 좋아요 알림이면 quote_id 또는 review_id, 팔로우면 둘 다 null.
  final String? quoteId;
  final String? reviewId;

  /// 좋아요 대상(인용구/후기)이 속한 책 — 탭 시 책 상세로 이동.
  final String? targetBookId;

  /// 대상 본문 미리보기(본인 콘텐츠). 잠금 인용구 등은 null.
  final String? preview;

  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromRow(Map<String, dynamic> r) {
    DateTime? parseTs(Object? v) =>
        v == null ? null : DateTime.parse(v as String);
    return AppNotification(
      id: r['id'] as String,
      type: NotificationType.fromName(r['type'] as String?),
      actorId: r['actor_id'] as String,
      actorDisplayName: r['actor_display_name'] as String?,
      actorAvatarUrl: r['actor_avatar_url'] as String?,
      quoteId: r['quote_id'] as String?,
      reviewId: r['review_id'] as String?,
      targetBookId: r['target_book_id'] as String?,
      preview: r['preview'] as String?,
      readAt: parseTs(r['read_at']),
      createdAt: parseTs(r['created_at'])!,
    );
  }
}
