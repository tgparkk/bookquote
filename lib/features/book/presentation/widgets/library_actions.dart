// 책 상세의 서재·인용구 액션 — "이 책 인용구 추가" CTA, "서재에 담기"/"✓ 서재에
// 있음" 버튼, 둘을 묶는 1줄 액션 행(PR30-B). 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/auth_state_provider.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../data/book_repository.dart';
import '../../state/book_providers.dart';

// ── "이 책 인용구 추가" CTA ────────────────────────────────

class AddQuoteButton extends StatelessWidget {
  const AddQuoteButton({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    // `/quote/new`는 인증 가드라 미로그인이면 라우터가 로그인으로 보냈다 복귀시킨다.
    final colors = context.colors;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accentDefault,   // accent500 → accentDefault
        foregroundColor: colors.accentOnAccent,  // secondary50 → accentOnAccent
        minimumSize: const Size(double.infinity, 48),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.base,
        ),
      ),
      icon: const Icon(Icons.add),
      label: const Text('이 책 인용구 추가'),
      onPressed: () => context.push('/quote/new?bookId=$bookId'),
    );
  }
}

// ── "서재에 담기" / "✓ 서재에 있음" ────────────────────────

class LibraryActionButton extends ConsumerStatefulWidget {
  const LibraryActionButton({
    super.key,
    required this.bookId,
    required this.prominent,
  });

  final String bookId;

  /// true면 큰 ElevatedButton(deep link 진입 시), false면 보조 OutlinedButton.
  final bool prominent;

  @override
  ConsumerState<LibraryActionButton> createState() =>
      _LibraryActionButtonState();
}

class _LibraryActionButtonState extends ConsumerState<LibraryActionButton> {
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).addToLibrary(widget.bookId);
      if (!mounted) return;
      ref.invalidate(isInLibraryProvider(widget.bookId));
      ref.invalidate(myLibraryProvider);
      showAppSnackBarOn(
        messenger,
        '서재에 담았어요',
        action: SnackBarAction(
          label: '서재 보기',
          onPressed: () {
            if (mounted) context.go('/library');
          },
        ),
      );
    } on BookRepositoryException catch (e) {
      if (!mounted) return;
      showAppSnackBarOn(
        messenger,
        e.code == 'NOT_AUTHENTICATED'
            ? '로그인이 필요해요.'
            : '서재에 담지 못했어요. 다시 시도해주세요.',
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBarOn(messenger, '서재에 담지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPressed() {
    final loggedIn = ref.read(currentSessionProvider) != null;
    if (!loggedIn) {
      // 로그인 후 이 화면(공유 진입이면 ?from=share까지)으로 복귀 — payload 보존.
      final back = Uri.encodeComponent(
        '/book/${widget.bookId}${widget.prominent ? '?from=share' : ''}',
      );
      context.push('/auth/login?from=$back');
      return;
    }
    _add();
  }

  @override
  Widget build(BuildContext context) {
    final inLibrary =
        ref.watch(isInLibraryProvider(widget.bookId)).value ?? false;

    if (inLibrary) {
      final chip = _InLibraryChip(
        label: widget.prominent ? '이미 서재에 있어요' : '서재에 있음',
      );
      return Align(
        alignment: widget.prominent ? Alignment.center : Alignment.centerLeft,
        child: chip,
      );
    }

    final colors = context.colors;
    final onPressed = _busy ? null : _onPressed;
    final spinner = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        // secondary50 → accentOnAccent, accent600 → accentDefault
        color: widget.prominent ? colors.accentOnAccent : colors.accentDefault,
      ),
    );

    if (widget.prominent) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentDefault,   // accent500 → accentDefault
          foregroundColor: colors.accentOnAccent,  // secondary50 → accentOnAccent
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontWeight: FontWeight.w600,
            fontSize: AppFontSize.base,
          ),
        ),
        icon: _busy ? spinner : const Icon(Icons.library_add),
        label: const Text('내 서재에 담기'),
        onPressed: onPressed,
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.accentDefault,               // accent600 → accentDefault
        side: BorderSide(color: colors.accentDefault),       // accent500 → accentDefault, const 제거
        minimumSize: const Size(double.infinity, 44),
      ),
      icon: _busy ? spinner : const Icon(Icons.library_add_outlined, size: 18),
      label: const Text('서재에 담기'),
      onPressed: onPressed,
    );
  }
}

class _InLibraryChip extends StatelessWidget {
  const _InLibraryChip({this.label = '서재에 있음'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.semanticSuccessLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.semanticSuccess),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w500,
              color: AppColors.semanticSuccess,
            ),
          ),
        ],
      ),
    );
  }
}

// ── PR30-B: 액션 행 (인용구 추가 + 서재 담기 1줄) ─────────────────────

/// "이 책 인용구 추가"(주) + "서재에 담기"(보조)를 1줄 Row로 묶는다. 미로그인이나
/// 이미 서재에 있는 책이면 보조 측 위젯이 알아서 자체 렌더(`LibraryActionButton`이
/// 칩 형태로 자동 전환). deep link 진입(fromShare=true)이면 상단 큰 CTA로
/// 이미 노출되므로 보조 버튼은 표시하지 않는다(이 위젯 자체를 부르지 않는다).
class PrimaryActionRow extends StatelessWidget {
  const PrimaryActionRow({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AddQuoteButton(bookId: bookId),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          flex: 2,
          child: LibraryActionButton(bookId: bookId, prominent: false),
        ),
      ],
    );
  }
}
