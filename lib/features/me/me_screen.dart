// "내 정보" 화면 — 프로필 · 내 데이터(요약·내보내기) · 설정 · 정보(약관/개인정보/버전/문의)
// · 계정(로그아웃 · 회원 탈퇴). 섹션형 ListView.
//
// 설계: docs/design/screens/me.md
// - "친구 찾기"는 V1엔 숨김(렌더 안 함). 화면 테마(시스템/라이트/다크) 토글은 설정 섹션(DM-C).
// - 출시 블로커: in-app 계정 삭제(Edge Function `delete-account`), 이용약관·개인정보처리방침
//   호스팅 URL — 아래 상수의 TODO 참고 / STAGES Stage 5.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/app_snackbar.dart';
import '../account/account_deletion.dart';
import '../auth/auth_controller.dart';
import '../follow/state/follow_providers.dart';
import '../profile/data/profile_repository.dart';
import '../profile/presentation/profile_settings_tiles.dart';
import '../quote/data/quote_outbox.dart';
import '../support/presentation/support_sheet.dart';
import 'data/quote_export.dart';
import 'state/me_providers.dart';

// 정적 페이지는 `docs/terms/index.html` + `docs/privacy/index.html`에 작성됨(2026-05-16).
// 실제 URL이 동작하려면 GitHub 저장소 Settings > Pages에서 Source = `main /docs` 활성화 필요.
// (Pages 활성화 후엔 본 URL이 자동으로 살아남 — STAGES Stage 5의 두 번째 블로커 해제.)
const String _termsUrl = 'https://tgparkk.github.io/bookquote/terms';
const String _privacyUrl = 'https://tgparkk.github.io/bookquote/privacy';
const String _supportEmail = 'sttgpark@gmail.com';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:loggedIn, :email) = ref.watch(meSessionInfoProvider);
    final displayName = ref.watch(myProfileProvider).value?.displayName;

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.s4, bottom: AppSpacing.s16),
        children: [
          _ProfileHeader(
            displayName: displayName,
            email: email,
            loggedIn: loggedIn,
          ),

          if (loggedIn) ...[
            const _SectionHeader('내 데이터'),
            _CountTile(
              icon: Icons.format_quote_outlined,
              title: '인용구',
              unit: '개',
              count: ref.watch(myQuoteCountProvider),
              onTap: () => context.go('/library?tab=quotes'),
            ),
            _CountTile(
              icon: Icons.menu_book_outlined,
              title: '서재',
              unit: '권',
              count: ref.watch(myBookCountProvider),
              onTap: () => context.go('/library'),
            ),
            _ActionTile(
              icon: Icons.ios_share,
              title: 'Markdown으로 내보내기',
              onTap: () => exportMyQuotesAsMarkdown(context: context, ref: ref),
            ),
          ],

          if (loggedIn) ...[
            const _SectionHeader('친구'),
            _CountTile(
              icon: Icons.group_outlined,
              title: '내 친구',
              unit: '명',
              count: ref.watch(myFollowingCountProvider),
              onTap: () => context.push('/me/following'),
            ),
            _ActionTile(
              icon: Icons.emoji_events_outlined,
              title: '친구 독서량 순위',
              onTap: () => context.push('/me/friends-ranking'),
            ),
            _ActionTile(
              icon: Icons.people_outline,
              title: '친구 찾기',
              onTap: () => context.push('/me/friend-search'),
            ),
            _ActionTile(
              icon: Icons.block,
              title: '차단 목록',
              onTap: () => context.push('/me/blocked'),
            ),
          ],

          const _SectionHeader('설정'),
          if (loggedIn) ...[
            const ProfilePublicToggleTile(),
            const DisplayNameTile(),
            _ActionTile(
              icon: Icons.key_outlined,
              title: '잠금 비밀번호',
              onTap: () => context.push('/me/lock-password'),
            ),
            _ActionTile(
              icon: Icons.notifications_none,
              title: '알림',
              onTap: () => context.push('/me/notifications'),
            ),
          ],
          const _ThemeModeTile(),

          const _SectionHeader('정보'),
          _AppVersionTile(version: ref.watch(appVersionProvider)),
          _ActionTile(
            icon: Icons.mail_outline,
            title: '문의하기',
            onTap: () => _openUri(
              context,
              Uri.parse(
                'mailto:$_supportEmail?subject=${Uri.encodeComponent('책글귀 문의')}',
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () => _openUri(context, Uri.parse(_termsUrl)),
          ),
          _ActionTile(
            icon: Icons.lock_outline,
            title: '개인정보처리방침',
            onTap: () => _openUri(context, Uri.parse(_privacyUrl)),
          ),
          // 후원 IAP '차 한 잔' (2026-07-03 수익모델 협의) — 정보 섹션 말미,
          // 로그아웃·탈퇴와 시각적으로 격리된 위치. 비로그인도 후원 가능.
          _ActionTile(
            icon: Icons.local_cafe_outlined,
            title: '개발자에게 차 한 잔',
            onTap: () => showSupportSheet(context),
          ),

          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
            child: Center(
              child: loggedIn
                  ? const _LogoutButton()
                  : OutlinedButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text('로그인하기'),
                    ),
            ),
          ),

          if (loggedIn) ...[
            const SizedBox(height: AppSpacing.s6),
            Center(
              child: TextButton(
                onPressed: () => runAccountDeletionFlow(context: context, ref: ref),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.semanticError,
                ),
                child: Text(
                  '회원 탈퇴',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.semanticError),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `mailto:`·`https:` 등을 외부 앱으로 연다. 실패하면 토스트(크래시 금지 — 8원칙).
Future<void> _openUri(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    showAppSnackBarOn(messenger, '열 수 없어요. 잠시 후 다시 시도해주세요.');
  }
}

// ── 프로필 ────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.loggedIn,
  });
  final String? displayName;
  final String? email;
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim() ?? '';
    final emailStr = email?.trim() ?? '';
    // 대표 줄은 닉네임 우선 — 카카오 OAuth 사용자는 이메일이 없어 닉네임이
    // 유일한 식별자다. "이메일 없음"을 빈 상태처럼 보이게 두지 않는다.
    final primary = name.isNotEmpty
        ? name
        : (emailStr.isNotEmpty ? emailStr : '책글귀 사용자');
    // 보조 줄: 닉네임이 대표 줄일 때만 이메일을 덧붙인다(같은 값 중복 방지).
    final secondary =
        (name.isNotEmpty && emailStr.isNotEmpty) ? emailStr : '로그인됨';
    final initial =
        loggedIn && primary.isNotEmpty ? primary[0].toUpperCase() : '?';

    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s2,
        AppSpacing.s6,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            // 프로필 배경: accent100 → accentContainer (다크에서 반전 대응)
            backgroundColor: colors.accentContainer,
            child: Text(
              initial,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                // 이니셜 글자: accent700 → accentOnContainer
                color: colors.accentOnContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loggedIn ? primary : '로그인 정보 없음',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // 메인 텍스트: primary800 → onSurface
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  loggedIn ? secondary : '아래에서 다시 로그인할 수 있어요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // 보조 텍스트: primary400 → onSurfaceSubtle
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colors.onSurfaceSubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s2,
      ),
      child: Text(
        label,
        // 섹션 헤더: primary400 → onSurfaceSubtle
        style: AppTextStyles.labelMedium.copyWith(color: context.colors.onSurfaceSubtle),
      ),
    );
  }
}

// ── 타일들 ────────────────────────────────────────────────

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.title,
    required this.unit,
    required this.count,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String unit;
  final AsyncValue<int> count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = count.when(
      data: (n) => '$n$unit',
      loading: () => '…',
      error: (_, _) => '—',
    );
    final colors = context.colors;
    return ListTile(
      // 아이콘: primary500 → iconPrimary
      leading: Icon(icon, color: colors.iconPrimary, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            // 카운트 텍스트: primary400 → onSurfaceSubtle
            style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceSubtle),
          ),
          const SizedBox(width: AppSpacing.s1),
          // chevron: primary300 → iconMuted
          Icon(Icons.chevron_right, color: colors.iconMuted, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      // 아이콘: primary500 → iconPrimary
      leading: Icon(icon, color: colors.iconPrimary, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge),
      // chevron: primary300 → iconMuted
      trailing: Icon(Icons.chevron_right, color: colors.iconMuted, size: 20),
      onTap: onTap,
    );
  }
}

/// 화면 테마 선택 타일 (DM-C) — 시스템/라이트/다크. 현재 값 표시 + 탭하면 시트.
class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final colors = context.colors;
    return ListTile(
      leading: Icon(Icons.brightness_6_outlined, color: colors.iconPrimary, size: 22),
      title: Text('화면 테마', style: AppTextStyles.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            themeModeLabel(mode),
            style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceSubtle),
          ),
          const SizedBox(width: AppSpacing.s1),
          Icon(Icons.chevron_right, color: colors.iconMuted, size: 20),
        ],
      ),
      onTap: () => _showThemeModeSheet(context, ref, mode),
    );
  }
}

/// 화면 테마 선택 바텀시트 — 선택 시 즉시 반영 + 영속(ThemeModeNotifier.set).
Future<void> _showThemeModeSheet(
  BuildContext context,
  WidgetRef ref,
  ThemeMode current,
) async {
  final selected = await showModalBottomSheet<ThemeMode>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s6,
                AppSpacing.s4,
                AppSpacing.s6,
                AppSpacing.s2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '화면 테마',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: colors.onSurfaceSubtle),
                ),
              ),
            ),
            for (final m in ThemeMode.values)
              ListTile(
                title: Text(themeModeLabel(m), style: AppTextStyles.bodyLarge),
                trailing: m == current
                    ? Icon(Icons.check, color: colors.accentDefault)
                    : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      );
    },
  );
  if (selected != null) {
    await ref.read(themeModeProvider.notifier).set(selected);
  }
}

class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile({required this.version});
  final AsyncValue<({String version, String buildNumber})> version;

  @override
  Widget build(BuildContext context) {
    final label = version.when(
      data: (v) => '${v.version} (${v.buildNumber})',
      loading: () => '…',
      error: (_, _) => '—',
    );
    final colors = context.colors;
    return ListTile(
      // 아이콘: primary500 → iconPrimary
      leading: Icon(Icons.info_outline, color: colors.iconPrimary, size: 22),
      title: Text('앱 버전', style: AppTextStyles.bodyLarge),
      trailing: Text(
        label,
        // 버전 값: primary400 → onSurfaceSubtle
        style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceSubtle),
      ),
    );
  }
}

// ── 로그아웃 ──────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    return OutlinedButton.icon(
      onPressed: isSigningOut ? null : () => _signOut(context, ref),
      icon: const Icon(Icons.logout, size: 18),
      label: Text(isSigningOut ? '로그아웃 중…' : '로그아웃'),
    );
  }
}

/// 로그아웃 — 아웃박스에 동기화 대기 중인 인용구가 있으면 경고 다이얼로그 먼저(데이터 유실 방지).
Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  var pending = 0;
  try {
    final outbox = await ref.read(quoteOutboxProvider.future);
    pending = outbox.pending().length;
  } catch (_) {
    // 아웃박스를 못 읽으면 경고는 생략하고 그냥 진행.
  }

  if (pending > 0) {
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: Text(
          '아직 동기화 안 된 인용구 $pending개가 있어요. 로그아웃하면 이 기기에서 사라질 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '그래도 로그아웃',
              style: TextStyle(color: AppColors.semanticError),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }

  await ref.read(authControllerProvider.notifier).signOut();
}
