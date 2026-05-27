// PR29: 책 후기 작성·수정 BottomSheet.
//
// 본문 textarea + 글자 수 카운터 + 저장/취소. 저장 시 trim한 텍스트를 caller에게
// pop으로 돌려준다. 영속화·invalidate는 호출 측(BookReviewSection)이 처리 —
// 시트는 입력에만 관여.

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../domain/book_review.dart';

class BookReviewInputSheet extends StatefulWidget {
  const BookReviewInputSheet({super.key, this.initialText = ''});
  final String initialText;

  @override
  State<BookReviewInputSheet> createState() => _BookReviewInputSheetState();
}

class _BookReviewInputSheetState extends State<BookReviewInputSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text;
    final err = BookReviewLimits.validate(raw);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(raw.trim());
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isEdit = widget.initialText.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s4,
        AppSpacing.s6,
        AppSpacing.s4 + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시트 핸들 + 제목
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            isEdit ? '후기 수정' : '후기 쓰기',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w700,
              color: AppColors.primary900,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            '책을 다 읽고 남는 감상을 1~5문단으로 자유롭게 적어보세요.',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          ConstrainedBox(
            // 키보드 위 안전한 높이 — 너무 크면 시트가 화면 가득 차고 너무
            // 작으면 5문단 입력이 답답함. 12줄 정도.
            constraints: const BoxConstraints(minHeight: 180, maxHeight: 320),
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              maxLength: BookReviewLimits.maxLength,
              style: TextStyle(
                fontFamily: AppFonts.quote,
                fontSize: AppFontSize.base,
                height: AppLineHeight.loose,
                color: AppColors.primary900,
              ),
              decoration: InputDecoration(
                hintText: '이 책이 어떻게 읽혔는지…',
                hintStyle: TextStyle(
                  fontFamily: AppFonts.quote,
                  color: AppColors.primary400,
                ),
                errorText: _error,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                counterStyle: TextStyle(
                  fontFamily: AppFonts.ui,
                  color: AppColors.primary400,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              const SizedBox(width: AppSpacing.s2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent500,
                  foregroundColor: AppColors.secondary50,
                ),
                onPressed: _submit,
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
