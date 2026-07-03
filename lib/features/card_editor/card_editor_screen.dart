// 카드 에디터 — Stage 3 PR9.
//
// quote+book 실데이터(`quoteCardDataProvider`)를 기반으로 `CardEditorController`가
// templateId/ratio/watermarkEnabled를 보유. 진입 시 저장된 draft가 있으면
// "이어서 만들기" 다이얼로그(`card-editor.md §4 편집 상태 영속화`).
//
// 후속 PR:
// - PR10: card_renderer (RepaintBoundary.toImage) + share_sheet — AppBar 공유 버튼
// - PR11: cards 테이블 + 공유 성공 시 비차단 INSERT
// - PR12: 5스와치 적용/다른 느낌 ↻/언두·redo/폰트 ±/auto-fit 경고/접근성

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/auth_state_provider.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/app_snackbar.dart';
import '../../core/ui/app_status_view.dart';
import '../crypto/presentation/lock_dialogs.dart';
import 'data/card_renderer.dart';
import 'data/card_repository.dart';
import 'domain/quote_card_data.dart';
import 'presentation/widgets/editor_panel.dart';
import 'presentation/widgets/share_sheet.dart';
import 'state/card_editor_controller.dart';
import 'state/quote_card_data_provider.dart';

enum _AppBarAction { editQuote, toggleWatermark }

class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  bool _initialized = false;
  bool _isSharing = false;
  // 본문 수정 후 복귀 시 다이얼로그 없이 silent로 초기화 (B3). 사용자가 같은
  // 세션 흐름이라 "이어서 만들기" 재질문은 마찰 — draft 있으면 그대로 적용.
  bool _skipDraftDialog = false;
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(cardEditorControllerProvider.notifier).attach(widget.quoteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(quoteCardDataProvider(widget.quoteId));
    final data = dataAsync.value;
    return Scaffold(
      backgroundColor: AppColors.secondary300,
      appBar: _buildAppBar(data),
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            onRetry: () =>
                ref.invalidate(quoteCardDataProvider(widget.quoteId)),
          ),
          data: (data) {
            if (data == null) return const _NotFoundView();
            // PR16-C-2: 잠금 + 키 없음 — 편집·공유 자체를 막고 안내. controller
            // 초기화도 건너뜀(잠금 인용구라 추천 디자인 의미 없음).
            // PR16-D: [잠금 해제] 1탭으로 같은 화면에서 UnlockDialog 진입.
            if (data.isLockedAndUnreadable) {
              return _LockedView(onUnlock: _onUnlockTap);
            }
            if (!_initialized) {
              _initialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeFromData(data);
              });
            }
            return CardEditorPanel(data: data, captureKey: _captureKey);
          },
        ),
      ),
      // F4: [공유] 버튼을 AppBar 우상단 → 하단 Full-width로 이동. 한 손 엄지 도달
      // 보장(S1·S14 페르소나). data 있을 때만 노출. 잠금 + 키 없음이면 숨김.
      bottomNavigationBar:
          data == null || data.isLockedAndUnreadable ? null : _buildShareBar(data),
    );
  }

  Widget _buildShareBar(QuoteCardData data) {
    final ratio = ref.watch(cardEditorControllerProvider).ratio;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s2,
          AppSpacing.s4,
          AppSpacing.s2,
        ),
        child: FilledButton.icon(
          onPressed: _isSharing ? null : () => _onShareTap(data, ratio),
          icon: _isSharing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text('공유'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent500,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.base,
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(QuoteCardData? data) {
    if (data == null) {
      return AppBar(title: const Text('카드 만들기'));
    }
    final state = ref.watch(cardEditorControllerProvider);
    final controller = ref.read(cardEditorControllerProvider.notifier);
    return AppBar(
      title: const Text('카드 만들기'),
      actions: <Widget>[
        IconButton(
          tooltip: state.canUndo ? '되돌리기' : '되돌릴 작업 없음',
          onPressed: state.canUndo ? controller.undo : null,
          icon: Icon(
            Icons.undo_rounded,
            color: state.canUndo
                ? AppColors.primary600
                : AppColors.primary300,
          ),
        ),
        // F4: [공유] 버튼은 하단 bottomNavigationBar(`_buildShareBar`)로 이동.
        // AppBar에는 undo + overflow 메뉴만 잔류.
        // 부차 액션은 overflow 메뉴로 묶어 폭 확보.
        PopupMenuButton<_AppBarAction>(
          tooltip: '더보기',
          icon: const Icon(Icons.more_vert, color: AppColors.primary600),
          onSelected: (v) {
            switch (v) {
              case _AppBarAction.editQuote:
                _onEditQuoteTap();
              case _AppBarAction.toggleWatermark:
                controller.toggleWatermark();
                // F10: 토글 후 상태를 명시적으로 안내. 팝업 메뉴가 닫혀 사용자가
                // 현재 ON/OFF 상태를 시각적으로 즉시 파악하기 어려웠음.
                if (!mounted) return;
                final next = ref.read(cardEditorControllerProvider);
                showAppSnackBar(
                  context,
                  next.watermarkEnabled ? '워터마크를 켰어요' : '워터마크를 껐어요',
                  duration: const Duration(milliseconds: 1500),
                );
            }
          },
          itemBuilder: (_) => <PopupMenuEntry<_AppBarAction>>[
            const PopupMenuItem<_AppBarAction>(
              value: _AppBarAction.editQuote,
              child: Row(
                children: <Widget>[
                  Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary600),
                  SizedBox(width: AppSpacing.s2),
                  Text('본문 수정'),
                ],
              ),
            ),
            PopupMenuItem<_AppBarAction>(
              value: _AppBarAction.toggleWatermark,
              child: Row(
                children: <Widget>[
                  Icon(
                    state.watermarkEnabled
                        ? Icons.copyright_rounded
                        : Icons.copyright_outlined,
                    size: 18,
                    color: state.watermarkEnabled
                        ? AppColors.accent500
                        : AppColors.primary600,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(state.watermarkEnabled ? '워터마크 끄기' : '워터마크 켜기'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 본문 수정 진입점. quote 입력 화면을 편집 모드로 열고, 복귀 시 카드 데이터를
  /// invalidate해 미리보기에 변경 본문이 즉시 반영되도록 한다.
  ///
  /// B3: `_initialized=false`로 리셋해 새 data가 도착하면 `_initializeFromData`가
  /// 재실행되도록 한다. 단 `_skipDraftDialog=true`로 표시해 "이어서 만들기"
  /// 다이얼로그 재발 없이 silent 적용(같은 작업 흐름이므로).
  Future<void> _onEditQuoteTap() async {
    await context.push('/quote/new?quoteId=${widget.quoteId}');
    if (!mounted) return;
    ref.invalidate(quoteCardDataProvider(widget.quoteId));
    setState(() {
      _initialized = false;
      _skipDraftDialog = true;
    });
  }

  /// PR16-D: _LockedView [잠금 해제] 핸들러. UnlockDialog로 마스터키 캐시.
  /// 성공 시 quote provider invalidate → 새 fetch에서 본문 복호화 → 정상 에디터
  /// 화면이 자동 재진입. `_initialized=false`로 controller 재초기화 트리거.
  Future<void> _onUnlockTap() async {
    final ok = await ensureMasterKeyReady(context, ref);
    if (!ok || !mounted) return;
    ref.invalidate(quoteCardDataProvider(widget.quoteId));
    setState(() => _initialized = false);
  }

  Future<void> _onShareTap(QuoteCardData data, CardRatio ratio) async {
    if (_isSharing) return;
    // PR16-C-2: 잠금 인용구는 공유 직전 평문 경고 — 본문 잠금과 이미지 공유의
    // 의미를 혼동하지 않게. 사용자 [취소]면 공유 흐름 중단(_isSharing 토글 전).
    if (data.isPrivate) {
      final ok = await showPrivateShareWarningDialog(context);
      if (!ok || !mounted) return;
    }
    setState(() => _isSharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await renderCardPng(
        boundaryKey: _captureKey,
        ratio: ratio,
      );
      if (!mounted) return;
      // PR11: 시트가 열리는 시점에 fire-and-forget으로 공유 이력 기록.
      // await 안 함 — 실패해도 공유 자체 흐름엔 영향 없음(repository에서 swallow).
      unawaited(
        ref.read(cardRepositoryProvider).recordShare(
              quoteId: widget.quoteId,
              bookId: data.bookId,
              design: ref.read(cardEditorControllerProvider),
            ),
      );
      await showCardShareSheet(
        context: context,
        file: file,
        shareText: data.quoteText,
        bookId: data.bookId,
        bookIsbn13: data.bookIsbn13,
        bookTitle: data.bookTitle,
        bookAuthor: data.bookAuthor,
        quotePage: data.quotePage,
        senderUid: ref.read(currentUserIdProvider),
      );
    } on CardRenderException {
      if (!mounted) return;
      showAppSnackBarOn(messenger, '카드 만들기에 실패했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _initializeFromData(QuoteCardData data) async {
    final controller = ref.read(cardEditorControllerProvider.notifier);
    final draft = await controller.readDraft();
    if (!mounted) return;

    // B3: 본문 수정 후 복귀 — 사용자가 작업 흐름 중이므로 다이얼로그 없이
    // draft가 있으면 그대로 유지(템플릿/비율 등 디자인 보존), 없으면 새 추천.
    if (_skipDraftDialog) {
      _skipDraftDialog = false;
      if (draft != null) {
        controller.applyState(draft);
      } else {
        controller.applyRecommended(
          charCount: data.charCount,
          hasCover: data.hasCover,
        );
      }
      return;
    }

    if (draft != null) {
      final restore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('편집하던 카드가 있어요'),
          content: const Text('이어서 만들까요, 새로 시작할까요?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('새로 시작'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('이어서 만들기'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (restore == true) {
        controller.applyState(draft);
      } else {
        await controller.clearDraft();
        if (!mounted) return;
        controller.applyRecommended(
          charCount: data.charCount,
          hasCover: data.hasCover,
        );
      }
    } else {
      controller.applyRecommended(
        charCount: data.charCount,
        hasCover: data.hasCover,
      );
    }
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    // 카드 에디터 화면 크롬 — 고정 팔레트(AppColors) 유지, context.colors 금지.
    return AppStatusView(
      icon: Icons.search_off_rounded,
      iconSize: 56,
      iconColor: AppColors.primary400,
      title: '이 인용구를 찾을 수 없어요',
      titleStyle: Theme.of(context).textTheme.titleMedium,
      subtitle: '삭제됐거나 권한이 없는 인용구일 수 있어요.',
      subtitleStyle: const TextStyle(color: AppColors.primary500),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppStatusView(
      icon: Icons.error_outline_rounded,
      iconSize: 56,
      iconColor: AppColors.primary400,
      title: '카드 정보를 불러오지 못했어요',
      titleStyle: Theme.of(context).textTheme.titleMedium,
      actions: [
        FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}

/// 잠금 인용구이지만 이 기기에서 본문 복호화 키가 준비되지 않은 상태.
/// PR16-C-2 — 편집·공유 진입을 봉쇄하고 사용자에게 잠금 해제 경로를 안내.
/// PR16-D — [잠금 해제] 1탭으로 이 화면에서 바로 UnlockDialog 진입.
class _LockedView extends StatelessWidget {
  const _LockedView({this.onUnlock});

  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: AppColors.primary400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '이 기기에서 잠긴 인용구',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            const Text(
              '본문이 잠겨 있어요. 잠금 비밀번호로 풀면\n카드로 만들 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.primary500),
            ),
            if (onUnlock != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s6),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.lock_open_outlined, size: 18),
                label: const Text('잠금 해제'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent500,
                  foregroundColor: AppColors.secondary50,
                  minimumSize: const Size.fromHeight(48),
                  textStyle: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontWeight: FontWeight.w600,
                    fontSize: AppFontSize.base,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
