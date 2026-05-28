// 카드 공유 시트 — Stage 3 PR10.
//
// `card-share.md §2~5` 명세 기반. 4버튼(카카오톡·인스타·이미지 저장·다른 앱)이지만
// V1은 모두 `share_plus.shareXFiles` OS 시트로 통합 — 카카오/인스타 SDK·`gal`은 V1.1.
// 막다른 골목 금지: 어떤 버튼도 비활성 없음(V1).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/share_service.dart';

/// 첫 공유 안내 SnackBar 1회 노출 플래그 (PR15-A — 차별화 강화 onboarding).
const String _kFirstShareHintShown = 'card_share_first_hint_shown_v1';

/// 받는 사람용 deep link scheme. AndroidManifest/Info.plist에 등록된 intent filter.
const String _kDeepLinkScheme = 'io.github.tgparkk.bookquote';

/// 카드 PNG가 준비된 뒤 호출. 사용자가 시트를 dismiss 해도 정상.
///
/// [bookId]와 [senderUid]가 둘 다 제공되면 공유 텍스트에 deep link를 포함한다
/// (`io.github.tgparkk.bookquote://book/<bookId>?from=share&sender=<senderUid>`).
/// 받는 사람이 링크를 탭하면 책 상세로 이동 + "[이 사람 서재 ▸]" 노출 — V1 K-factor
/// 핵심 다리 (PR20-C). bookId 없으면(manual_book_text만) deep link 미포함.
/// [bookIsbn13]이 있으면 교보문고 검색(구매) 링크도 공유 텍스트에 함께 첨부한다(V1.0).
Future<void> showCardShareSheet({
  required BuildContext context,
  required XFile file,
  String? shareText,
  String? bookId,
  String? bookIsbn13,
  String? bookTitle,
  String? bookAuthor,
  int? quotePage,
  String? senderUid,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.secondary100,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => _CardShareSheet(
      file: file,
      shareText: shareText,
      bookId: bookId,
      bookIsbn13: bookIsbn13,
      bookTitle: bookTitle,
      bookAuthor: bookAuthor,
      quotePage: quotePage,
      senderUid: senderUid,
    ),
  );
}

String? buildDeepLinkForShare({String? bookId, String? senderUid}) {
  if (bookId == null || bookId.isEmpty) return null;
  final base = '$_kDeepLinkScheme://book/$bookId?from=share';
  return (senderUid == null || senderUid.isEmpty)
      ? base
      : '$base&sender=$senderUid';
}

/// 책 ISBN13으로 교보문고 검색 링크를 만든다(공유 텍스트 첨부 — V1.0).
/// ISBN으로 직접 상품 URL은 만들 수 없어 검색 결과로 연결 — ISBN13은 unique라
/// 사실상 그 책 한 권. isbn13이 없으면(직접 입력 책) null.
String? buildBookPurchaseUrl(String? isbn13) {
  final v = isbn13?.trim() ?? '';
  if (v.isEmpty) return null;
  return 'https://search.kyobobook.co.kr/search'
      '?keyword=${Uri.encodeQueryComponent(v)}';
}

/// PR10 (2026-05-28): 알라딘 검색 링크. 책 상세 페이지 "구매처" chip에서 사용.
/// 교보문고와 같은 패턴 — ISBN13 검색 결과 페이지로 연결.
String? buildAladinSearchUrl(String? isbn13) {
  final v = isbn13?.trim() ?? '';
  if (v.isEmpty) return null;
  return 'https://www.aladin.co.kr/search/wsearchresult.aspx'
      '?SearchTarget=All&SearchWord=${Uri.encodeQueryComponent(v)}';
}

/// 공유 메시지 본문 — 책 출처(제목·저자·페이지) + deep link(K-factor) + 구매 링크
/// 순서로 조립. PR12 (2026-05-28)에서 출처 라인 추가 — 카드 이미지엔 박혀 있어도
/// 텍스트 공유에선 빠져 받는 쪽이 인용 출처를 모르던 문제 해소.
///
/// 모든 인자 비면 null(이미지만 공유).
String? buildShareMessage({
  String? bookTitle,
  String? bookAuthor,
  int? quotePage,
  String? deepLink,
  String? purchaseUrl,
}) {
  final citation = _buildCitationLine(
    bookTitle: bookTitle,
    bookAuthor: bookAuthor,
    quotePage: quotePage,
  );
  final parts = <String>[
    ?citation,
    if (deepLink != null && deepLink.isNotEmpty) deepLink,
    if (purchaseUrl != null && purchaseUrl.isNotEmpty)
      '📖 이 책 보러 가기 · 교보문고\n$purchaseUrl',
  ];
  return parts.isEmpty ? null : parts.join('\n\n');
}

/// "— 〈책 제목〉 김저자 (p.42)" 같은 출처 한 줄. 세 요소 모두 비면 null.
String? _buildCitationLine({
  String? bookTitle,
  String? bookAuthor,
  int? quotePage,
}) {
  final title = bookTitle?.trim() ?? '';
  final author = bookAuthor?.trim() ?? '';
  if (title.isEmpty && author.isEmpty && quotePage == null) return null;
  final buf = StringBuffer('— ');
  if (title.isNotEmpty) buf.write('〈$title〉');
  if (author.isNotEmpty) {
    if (title.isNotEmpty) buf.write(' ');
    buf.write(author);
  }
  if (quotePage != null) {
    if (title.isNotEmpty || author.isNotEmpty) buf.write(' ');
    buf.write('(p.$quotePage)');
  }
  return buf.toString();
}

class _CardShareSheet extends StatelessWidget {
  const _CardShareSheet({
    required this.file,
    required this.shareText,
    required this.bookId,
    required this.bookIsbn13,
    required this.bookTitle,
    required this.bookAuthor,
    required this.quotePage,
    required this.senderUid,
  });

  final XFile file;
  final String? shareText;
  final String? bookId;
  final String? bookIsbn13;
  final String? bookTitle;
  final String? bookAuthor;
  final int? quotePage;
  final String? senderUid;

  Future<void> _share(BuildContext context, String? prefix) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final deepLink = buildDeepLinkForShare(bookId: bookId, senderUid: senderUid);
    final text = buildShareMessage(
      bookTitle: bookTitle,
      bookAuthor: bookAuthor,
      quotePage: quotePage,
      deepLink: deepLink,
      purchaseUrl: buildBookPurchaseUrl(bookIsbn13),
    );
    try {
      await shareCardImage(
        file: file,
        subject: prefix == null ? null : '$prefix — 책글귀',
        text: text,
      );
      if (navigator.canPop()) navigator.pop();
      // PR15-A (2): 첫 공유 직후 단 1회 — "다른 곳에도 보낼 수 있어요" closure
      // 카피. 4단톡 순차 공유(S6) 같은 반복 시나리오에서 사용자에게 다음 동선이
      // 막다른 길이 아님을 알린다. SharedPreferences global flag로 1회 제한.
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool(_kFirstShareHintShown) ?? false)) {
          await prefs.setBool(_kFirstShareHintShown, true);
          messenger
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content: Text('공유했어요. 같은 카드를 다른 곳에도 보낼 수 있어요.'),
              duration: Duration(milliseconds: 2400),
            ));
        }
      } catch (_) {/* prefs 실패는 무시 — 공유는 이미 성공 */}
    } on CardShareException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s2,
          AppSpacing.s4,
          AppSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _KakaoButton(onTap: () => _share(context, '카카오톡')),
            const SizedBox(height: AppSpacing.s2),
            _OutlinedShareButton(
              icon: Icons.camera_alt_outlined,
              label: '인스타그램 스토리 (9:16)',
              onTap: () => _share(context, '인스타그램'),
            ),
            const SizedBox(height: AppSpacing.s2),
            _OutlinedShareButton(
              icon: Icons.download_rounded,
              label: '이미지 저장',
              onTap: () => _share(context, null),
            ),
            const SizedBox(height: AppSpacing.s2),
            _OutlinedShareButton(
              icon: Icons.more_horiz_rounded,
              label: '다른 앱으로 공유',
              onTap: () => _share(context, null),
            ),
            const SizedBox(height: AppSpacing.s4),
            const Text(
              '저장 권한이 없어도 공유는 그대로 할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.xxs,
                color: AppColors.primary400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카카오 브랜드 노랑(#FEE500)·검정 텍스트 — `card-share.md §5` 토큰 외 예외.
class _KakaoButton extends StatelessWidget {
  const _KakaoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEE500),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: const SizedBox(
          height: 52,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.chat_bubble_rounded,
                    size: 20, color: Color(0xFF191919)),
                SizedBox(width: AppSpacing.s2),
                Text(
                  '카카오톡 단톡방으로 보내기',
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontWeight: FontWeight.w600,
                    fontSize: AppFontSize.sm,
                    color: Color(0xFF191919),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedShareButton extends StatelessWidget {
  const _OutlinedShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary200, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 20, color: AppColors.primary700),
              const SizedBox(width: AppSpacing.s2),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.ui,
                  fontWeight: FontWeight.w500,
                  fontSize: AppFontSize.sm,
                  color: AppColors.primary700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
