// 인용구 본문 검색 — `showSearch` Material SearchDelegate (PR20-B).
//
// 홈 AppBar 🔍 + 서재 인용구 탭 검색 입력 둘 다 같은 delegate 재사용. 300ms
// 디버운스 후 `quoteSearchProvider(query)` watch. 잠금 인용구는 RLS·복호화 측에서
// text=null이라 ilike에 자연 제외(잠금 본문은 검색되지 않음 — 서버에 평문 0 원칙).
//
// 결과 카드 탭 → `/quote/:id/share`(바로 공유 — PR10.5). 단일 탭 short-cut.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../state/quote_providers.dart';
import 'widgets/quote_list_card.dart';

class QuoteSearchDelegate extends SearchDelegate<void> {
  QuoteSearchDelegate() : super(searchFieldLabel: '인용구 검색');

  // 매 키 입력마다 새 fetch면 비용 폭증 → 디버운스 후 결과 화면이 watch할 effective query.
  final ValueNotifier<String> _debounced = ValueNotifier<String>('');
  Timer? _timer;
  String _last = '';

  void _onQueryChanged(String q) {
    if (q == _last) return;
    _last = q;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      _debounced.value = q.trim();
    });
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    // 검색 화면도 본 앱 톤(secondary50 배경, primary 텍스트)을 유지.
    return Theme.of(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: '지우기',
        onPressed: () {
          query = '';
          _onQueryChanged('');
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  @override
  Widget buildResults(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    _onQueryChanged(query);
    return ValueListenableBuilder<String>(
      valueListenable: _debounced,
      builder: (context, effectiveQuery, _) {
        if (effectiveQuery.isEmpty) {
          return const _Hint();
        }
        return Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(quoteSearchProvider(effectiveQuery));
            return async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent500),
              ),
              error: (_, _) => const _ErrorView(),
              data: (items) {
                if (items.isEmpty) return _ZeroResult(query: effectiveQuery);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s2,
                    AppSpacing.s4,
                    AppSpacing.s16,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s3),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return QuoteListCard(
                      quote: item.quote,
                      book: item.book,
                      onTap: () {
                        close(context, null);
                        // hot 컨텍스트: 검색 결과에서 1탭 = 카드 펼침 대신 바로
                        // 공유 화면. 더 가벼운 retention loop (전문가 #3 R4).
                        context.push('/quote/${item.quote.id}/share');
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 56,
              color: AppColors.primary300,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '모은 인용구를 검색해요',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '본문 또는 책 제목 일부를 입력하세요.\n잠금 인용구는 검색에서 제외돼요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZeroResult extends StatelessWidget {
  const _ZeroResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.primary300,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '"$query"를 찾지 못했어요',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '다른 단어로 검색해보세요.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '검색 중 오류가 발생했어요.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary500),
      ),
    );
  }
}
