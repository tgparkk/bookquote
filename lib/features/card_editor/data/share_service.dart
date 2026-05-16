// 카드 공유 서비스 — Stage 3 PR10.
//
// `card_renderer`가 만든 임시 PNG를 OS 공유 시트로 띄운다. V1은 4버튼(카카오톡·인스타·
// 이미지 저장·다른 앱) 모두 `share_plus`의 OS 시트로 통합 — `screens/card-share.md §3`.
// 카카오 SDK 메시지 카드와 명시적 갤러리 저장(`gal`)은 V1.1.

import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

class CardShareException implements Exception {
  const CardShareException(this.message);
  final String message;
  @override
  String toString() => 'CardShareException: $message';
}

/// 카드 PNG를 OS 공유 시트로 보낸다. 사용자가 취소해도 정상(예외 아님).
/// 호출자는 `CardShareException`만 try/catch 하면 된다.
Future<ShareResult> shareCardImage({
  required XFile file,
  String? subject,
  Rect? sharePositionOrigin,
}) async {
  try {
    return await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[file],
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  } catch (e) {
    throw CardShareException('공유 시트를 열지 못했어요. ($e)');
  }
}
