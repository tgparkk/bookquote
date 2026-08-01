// 카드 공유 시트 — Stage 3 PR10.
//
// `card-share.md §2~5` 명세 기반. 4버튼(카카오톡·인스타·이미지 저장·다른 앱)이지만
// V1은 모두 `share_plus.shareXFiles` OS 시트로 통합 — 카카오/인스타 SDK·`gal`은 V1.1.
// 막다른 골목 금지: 어떤 버튼도 비활성 없음(V1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../data/share_service.dart';

/// 첫 공유 안내 SnackBar 1회 노출 플래그 (PR15-A — 차별화 강화 onboarding).
const String _kFirstShareHintShown = 'card_share_first_hint_shown_v1';

/// 공유 링크 랜딩 베이스 (GitHub Pages — `docs/b/index.html`).
///
/// 구 커스텀 스킴 딥링크(`io.github.tgparkk.bookquote://...`)는 미설치자에게
/// 클릭조차 안 되는 죽은 문자열이라 신규 유입 기여가 구조적으로 0이었다
/// (2026-08-01 출시 1개월 진단). https 랜딩은 설치자에겐 intent://로 같은
/// 스킴을 쏴 앱을 열고(기존 딥링크 수신 경로 무변경), 미설치자는 Play로 유도.
/// sender uid는 공개 URL 노출 문제로 링크에서 제거 — 받는 쪽
/// `book_overflow_menu`의 sender 처리는 구 링크 호환용으로 유지.
const String _kShareLandingBase = 'https://tgparkk.github.io/bookquote/b/';

/// 카드 PNG가 준비된 뒤 호출. 사용자가 시트를 dismiss 해도 정상.
///
/// [bookId]가 있으면 공유 텍스트에 https 랜딩 링크를 포함한다
/// (`https://tgparkk.github.io/bookquote/b/?id=<bookId>&from=share`).
/// bookId 없으면(manual_book_text만) 링크 미포함.
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
    ),
  );
}

/// 받는 사람용 https 랜딩 링크. bookId 없으면 null(이미지만 공유).
String? buildShareLandingLink({String? bookId}) {
  if (bookId == null || bookId.isEmpty) return null;
  return '$_kShareLandingBase?id=$bookId&from=share';
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

/// 공유 메시지 본문 — 책 출처(제목·저자·페이지) + 랜딩 링크(K-factor) + 구매 링크
/// 순서로 조립. PR12 (2026-05-28)에서 출처 라인 추가 — 카드 이미지엔 박혀 있어도
/// 텍스트 공유에선 빠져 받는 쪽이 인용 출처를 모르던 문제 해소.
///
/// 모든 인자 비면 null(이미지만 공유).
String? buildShareMessage({
  String? bookTitle,
  String? bookAuthor,
  int? quotePage,
  String? link,
  String? purchaseUrl,
}) {
  final citation = _buildCitationLine(
    bookTitle: bookTitle,
    bookAuthor: bookAuthor,
    quotePage: quotePage,
  );
  final parts = <String>[
    ?citation,
    if (link != null && link.isNotEmpty) link,
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
  });

  final XFile file;
  final String? shareText;
  final String? bookId;
  final String? bookIsbn13;
  final String? bookTitle;
  final String? bookAuthor;
  final int? quotePage;

  Future<void> _share(
    BuildContext context,
    String? prefix, {
    required String target,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final landingLink = buildShareLandingLink(bookId: bookId);
    final text = buildShareMessage(
      bookTitle: bookTitle,
      bookAuthor: bookAuthor,
      quotePage: quotePage,
      link: landingLink,
      purchaseUrl: buildBookPurchaseUrl(bookIsbn13),
    );
    // 카카오톡 1순위: SDK 메시지 템플릿 — 이미지+[책 보러 가기] 버튼이 한
    // 메시지로 전송(2026-08-01 사용자 결정: 공유 한 번으로 끝). 실패 시 아래
    // OS 공유 시트 2단 공유로 폴백.
    if (target == 'kakao') {
      final linkUri = Uri.parse(
        landingLink ??
            'https://play.google.com/store/apps/details?id=io.github.tgparkk.bookquote',
      );
      final sent = await shareCardViaKakaoTalk(
        file: file,
        linkUrl: linkUri,
        title: (bookTitle == null || bookTitle!.trim().isEmpty)
            ? '책글귀 — 책 속 한 줄'
            : '〈${bookTitle!.trim()}〉 속 한 줄',
        description: bookAuthor?.trim(),
      );
      if (sent) {
        appAnalytics.logCardShareSuccess('kakao_template');
        if (navigator.canPop()) navigator.pop();
        return;
      }
    }
    // 카카오톡(폴백)·인스타는 이미지 공유 시 텍스트(EXTRA_TEXT)를 드롭해 랜딩
    // 링크가 함께 안 간다. 링크는 공유 *전에* 복사해 둔다(안전망) — 공유 직후
    // 스낵바는 대상 앱이 전면에 떠서 보이지 않았음(2026-08-01 실기기 2회 확인).
    if (landingLink != null &&
        (target == 'kakao' || target == 'instagram')) {
      try {
        await Clipboard.setData(ClipboardData(text: landingLink));
      } catch (_) {/* 클립보드 실패 — 공유는 계속 */}
    }
    try {
      final result = await shareCardImage(
        file: file,
        subject: prefix == null ? null : '$prefix — 책글귀',
        text: text,
      );
      appAnalytics.logCardShareSuccess(target);
      // 카카오톡 2단 공유(2026-08-01 사용자 결정): 이미지 공유가 끝나고 앱으로
      // 돌아오면 링크 텍스트 공유 창을 한 번 더 연다 — 카톡에 이미지·링크가
      // 각각 한 메시지씩 도착. 첫 공유를 취소(dismissed)했으면 생략.
      if (target == 'kakao' &&
          text != null &&
          result.status == ShareResultStatus.success) {
        try {
          await shareTextOnly(text);
        } on CardShareException {/* 2차 공유 실패 — 링크는 클립보드에 있음 */}
      }
      if (navigator.canPop()) navigator.pop();
      // PR15-A (2): 첫 공유 직후 단 1회 — "다른 곳에도 보낼 수 있어요" closure
      // 카피. 4단톡 순차 공유(S6) 같은 반복 시나리오에서 사용자에게 다음 동선이
      // 막다른 길이 아님을 알린다. SharedPreferences global flag로 1회 제한.
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool(_kFirstShareHintShown) ?? false)) {
          await prefs.setBool(_kFirstShareHintShown, true);
          showAppSnackBarOn(
            messenger,
            '공유했어요. 같은 카드를 다른 곳에도 보낼 수 있어요.',
            duration: const Duration(milliseconds: 2400),
          );
        }
      } catch (_) {/* prefs 실패는 무시 — 공유는 이미 성공 */}
    } on CardShareException catch (e) {
      showAppSnackBarOn(messenger, e.message);
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
            _KakaoButton(onTap: () => _share(context, '카카오톡', target: 'kakao')),
            const SizedBox(height: AppSpacing.s2),
            _OutlinedShareButton(
              icon: Icons.camera_alt_outlined,
              label: '인스타그램 스토리 (9:16)',
              onTap: () => _share(context, '인스타그램', target: 'instagram'),
            ),
            const SizedBox(height: AppSpacing.s2),
            _OutlinedShareButton(
              icon: Icons.download_rounded,
              label: '이미지 저장',
              onTap: () => _share(context, null, target: 'save'),
            ),
            const SizedBox(height: AppSpacing.s2),
            _OutlinedShareButton(
              icon: Icons.more_horiz_rounded,
              label: '다른 앱으로 공유',
              onTap: () => _share(context, null, target: 'other'),
            ),
            const SizedBox(height: AppSpacing.s4),
            // 카톡·인스타의 EXTRA_TEXT 드롭 안내 — 공유 후 스낵바는 대상 앱이
            // 전면에 떠서 못 보므로(2026-08-01) 시트 안 상시 카피로 안내한다.
            if (bookId != null && bookId!.isNotEmpty) ...<Widget>[
              const Text(
                '카카오톡은 이미지와 [책 보러 가기] 버튼이 한 메시지로 전송돼요.\n인스타그램은 이미지만 전달돼요(앱 링크는 자동 복사).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.xxs,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
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
