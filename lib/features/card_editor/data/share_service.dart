// 카드 공유 서비스 — Stage 3 PR10.
//
// `card_renderer`가 만든 임시 PNG를 OS 공유 시트로 띄운다. V1은 4버튼(카카오톡·인스타·
// 이미지 저장·다른 앱) 모두 `share_plus`의 OS 시트로 통합 — `screens/card-share.md §3`.
// 카카오 SDK 메시지 카드와 명시적 갤러리 저장(`gal`)은 V1.1.

import 'dart:io' show File;
import 'dart:ui' show Rect;

import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';

class CardShareException implements Exception {
  const CardShareException(this.message);
  final String message;
  @override
  String toString() => 'CardShareException: $message';
}

/// 카드 PNG를 OS 공유 시트로 보낸다. 사용자가 취소해도 정상(예외 아님).
/// 호출자는 `CardShareException`만 try/catch 하면 된다.
///
/// [text]가 있으면 메시지 본문에 포함된다 — 보통 책 상세 deep link (V1 K-factor).
/// Kakao 같은 일부 앱은 이미지만 받고 텍스트를 드롭하지만, Telegram·SMS·메일 등
/// 대다수 경로에서 링크가 함께 전달된다.
Future<ShareResult> shareCardImage({
  required XFile file,
  String? subject,
  String? text,
  Rect? sharePositionOrigin,
}) async {
  try {
    return await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[file],
        subject: subject,
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  } catch (e) {
    throw CardShareException('공유 시트를 열지 못했어요. ($e)');
  }
}

/// 카카오톡 메시지 템플릿 공유 — 이미지와 [책 보러 가기] 버튼이 **한 메시지**로
/// 전송된다(2026-08-01 사용자 결정: 공유 한 번으로 링크까지). 카드 PNG를 카카오
/// CDN에 업로드한 뒤 Feed 템플릿으로 카카오톡을 연다.
///
/// 전제: 카카오 디벨로퍼스 콘솔 > 플랫폼 > Web에 랜딩 도메인
/// (`https://tgparkk.github.io`)이 등록돼 있어야 버튼 링크가 동작한다.
///
/// 카카오톡 미설치·업로드 실패 등 어떤 이유로든 불가하면 false — 호출자는
/// OS 공유 시트 2단 공유로 폴백한다.
Future<bool> shareCardViaKakaoTalk({
  required XFile file,
  required Uri linkUrl,
  required String title,
  String? description,
}) async {
  try {
    if (!await ShareClient.instance.isKakaoTalkSharingAvailable()) {
      return false;
    }
    final upload =
        await ShareClient.instance.uploadImage(image: File(file.path));
    final link = Link(webUrl: linkUrl, mobileWebUrl: linkUrl);
    final template = FeedTemplate(
      content: Content(
        title: title,
        description: description,
        imageUrl: Uri.parse(upload.infos.original.url),
        link: link,
      ),
      buttons: <Button>[Button(title: '책 보러 가기', link: link)],
    );
    final uri = await ShareClient.instance.shareDefault(template: template);
    await ShareClient.instance.launchKakaoTalk(uri);
    return true;
  } catch (_) {
    return false; // 폴백 경로가 있으므로 조용히 실패
  }
}

/// 텍스트만 OS 공유 시트로 보낸다 — 카카오톡 2단 공유(이미지 → 링크)용.
/// 카톡은 이미지 공유의 EXTRA_TEXT를 드롭하므로 링크를 별도 공유로 보낸다.
Future<ShareResult> shareTextOnly(
  String text, {
  Rect? sharePositionOrigin,
}) async {
  try {
    return await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: sharePositionOrigin),
    );
  } catch (e) {
    throw CardShareException('공유 시트를 열지 못했어요. ($e)');
  }
}
