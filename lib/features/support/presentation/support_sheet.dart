// 후원 시트 — "차 한 잔 건네기".
//
// `showSupportSheet(context)`로 모달 시트를 띄운다. 구매 완료 시 감사 화면으로
// 전환될 뿐 앱 기능은 아무것도 바뀌지 않는다(순수 후원 — 수익모델 협의 2026-07-03).
// 카피는 '구매'가 아니라 '관계'의 언어를 쓴다 (UI/UX 협의).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../data/support_service.dart';

/// 후원 시트를 띄운다.
Future<void> showSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: context.colors.surfaceSheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => const _SheetBody(),
  );
}

enum _SheetState { loading, unavailable, ready, pending, success }

class _SheetBody extends ConsumerStatefulWidget {
  const _SheetBody();

  @override
  ConsumerState<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends ConsumerState<_SheetBody> {
  var _state = _SheetState.loading;
  ProductDetails? _product;
  StreamSubscription<SupportPurchasePhase>? _phaseSub;

  @override
  void initState() {
    super.initState();
    final service = ref.read(supportServiceProvider);
    _phaseSub = service.phases.listen(_onPhase);
    service.loadProduct().then((product) {
      if (!mounted) return;
      setState(() {
        _product = product;
        _state = product == null ? _SheetState.unavailable : _SheetState.ready;
      });
    });
  }

  @override
  void dispose() {
    _phaseSub?.cancel();
    super.dispose();
  }

  void _onPhase(SupportPurchasePhase phase) {
    if (!mounted) return;
    setState(() {
      _state = switch (phase) {
        SupportPurchasePhase.pending => _SheetState.pending,
        SupportPurchasePhase.success => _SheetState.success,
        // 취소·실패 모두 조용히 원래 화면으로 — 후원 흐름에서 에러를
        // 다그치듯 보여주지 않는다.
        SupportPurchasePhase.canceled ||
        SupportPurchasePhase.error =>
          _product == null ? _SheetState.unavailable : _SheetState.ready,
      };
    });
  }

  Future<void> _buy() async {
    final product = _product;
    if (product == null) return;
    setState(() => _state = _SheetState.pending);
    final started = await ref.read(supportServiceProvider).buy(product);
    if (!started && mounted && _state == _SheetState.pending) {
      setState(() => _state = _SheetState.ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s3,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          const SizedBox(height: AppSpacing.s4),
          switch (_state) {
            _SheetState.loading => const _CenteredSpinner(),
            _SheetState.pending => const _CenteredSpinner(),
            _SheetState.unavailable => const _UnavailableView(),
            _SheetState.ready => _ReadyView(product: _product!, onBuy: _buy),
            _SheetState.success => const _ThanksView(),
          },
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.colors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: CircularProgressIndicator(color: context.colors.accentDefault),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.product, required this.onBuy});

  final ProductDetails product;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_cafe_outlined, size: 40, color: colors.accentDefault),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '이 공간이 마음에 드셨다면,\n차 한 잔 건네주세요.',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '조용히 혼자 만드는 앱입니다. 응원이 큰 힘이 됩니다.\n후원해도 앱은 지금 그대로예요 — 광고도, 잠긴 기능도 없습니다.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.s6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentDefault,
              foregroundColor: colors.accentOnAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
            ),
            onPressed: onBuy,
            child: Text('차 한 잔 건네기 · ${product.price}'),
          ),
        ),
      ],
    );
  }
}

class _ThanksView extends StatelessWidget {
  const _ThanksView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite_outline,
            size: 40, color: context.colors.accentDefault),
        const SizedBox(height: AppSpacing.s4),
        Text('따뜻한 차, 잘 받았어요.',
            textAlign: TextAlign.center, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '이 응원으로 책글귀를 오래오래 만들게요. 고맙습니다.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.s6),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_cafe_outlined,
            size: 40, color: context.colors.iconMuted),
        const SizedBox(height: AppSpacing.s4),
        Text('지금은 스토어에 연결할 수 없어요',
            textAlign: TextAlign.center, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '마음만으로도 충분해요. 다음에 다시 찾아주세요.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
