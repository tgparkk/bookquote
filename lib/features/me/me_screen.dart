// "내 정보" 화면 — 프로필 · 내 데이터(요약·내보내기) · 설정 · 정보(약관/개인정보/버전/문의)
// · 계정(로그아웃 · 회원 탈퇴). 섹션형 ListView.
//
// 설계: docs/design/screens/me.md
// - "친구 찾기"는 V1엔 숨김(렌더 안 함). 다크모드 토글은 V1.5.
// - 출시 블로커: in-app 계정 삭제(Edge Function `delete-account`), 이용약관·개인정보처리방침
//   호스팅 URL — 아래 상수의 TODO 참고 / STAGES Stage 5.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/tokens.dart';
import '../account/account_deletion.dart';
import '../auth/auth_controller.dart';
import '../quote/data/quote_outbox.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.s4, bottom: AppSpacing.s16),
        children: [
          _ProfileHeader(email: email, loggedIn: loggedIn),

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

          const _SectionHeader('설정'),
          if (loggedIn)
            _ActionTile(
              icon: Icons.key_outlined,
              title: '잠금 비밀번호',
              onTap: () => context.push('/me/lock-password'),
            ),
          const _ValueTile(
            icon: Icons.brightness_6_outlined,
            title: '다크 모드',
            value: '시스템 설정',
          ),
          const _ValueTile(
            icon: Icons.notifications_none,
            title: '알림',
            value: '곧 추가될 기능',
            disabled: true,
          ),

          const _SectionHeader('정보'),
          _AppVersionTile(version: ref.watch(appVersionProvider)),
          _ActionTile(
            icon: Icons.mail_outline,
            title: '문의하기',
            onTap: () => _openUri(
              context,
              Uri.parse(
                'mailto:$_supportEmail?subject=${Uri.encodeComponent('책귀 문의')}',
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
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('열 수 없어요. 잠시 후 다시 시도해주세요.')),
      );
  }
}

// ── 프로필 ────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.email, required this.loggedIn});
  final String? email;
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final trimmed = email?.trim() ?? '';
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

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
            backgroundColor: AppColors.accent100,
            child: Text(
              loggedIn ? initial : '?',
              style: const TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppColors.accent700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loggedIn ? (trimmed.isNotEmpty ? trimmed : '이메일 없음') : '로그인 정보 없음',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.primary800),
                ),
                const SizedBox(height: 2),
                Text(
                  loggedIn ? '로그인됨' : '아래에서 다시 로그인할 수 있어요',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary400),
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
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary400),
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
    return ListTile(
      leading: Icon(icon, color: AppColors.primary500, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary400),
          ),
          const SizedBox(width: AppSpacing.s1),
          const Icon(Icons.chevron_right, color: AppColors.primary300, size: 20),
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
    return ListTile(
      leading: Icon(icon, color: AppColors.primary500, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: const Icon(Icons.chevron_right, color: AppColors.primary300, size: 20),
      onTap: onTap,
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.value,
    this.disabled = false,
  });
  final IconData icon;
  final String title;
  final String value;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final titleColor = disabled ? AppColors.primary300 : AppColors.primary800;
    final iconColor = disabled ? AppColors.primary300 : AppColors.primary500;
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(color: titleColor)),
      trailing: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(
          color: disabled ? AppColors.primary300 : AppColors.primary400,
        ),
      ),
    );
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
    return ListTile(
      leading: const Icon(Icons.info_outline, color: AppColors.primary500, size: 22),
      title: Text('앱 버전', style: AppTextStyles.bodyLarge),
      trailing: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary400),
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
