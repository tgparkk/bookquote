// 인용구 입력 화면용 잠금 토글 행 (PR16-C-1).
//
// "🔒 이 인용구만 잠그기" 행. Switch 우측. 토글 OFF→ON 시 caller가
// ensureMasterKeyReady로 envelope/마스터키 준비를 보장한 뒤 onChanged(true)
// 호출 — 이 위젯은 시각만 담당, 비밀번호 모달은 caller가 띄운다.
//
// 잠금된 인용구는 본문이 AES-256-GCM으로 암호화되어 저장. 마스터키는 이 기기의
// flutter_secure_storage에 캐시. 비밀번호는 서버가 모름 → 비밀번호 분실 시 영구 손실.

import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/tokens.dart';

class LockToggleRow extends StatelessWidget {
  const LockToggleRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;

  /// null 이면 비활성. caller는 OFF→ON 전환 시 비밀번호 모달이 성공할 때만
  /// 콜백 본문에서 setState로 value를 true로 끌어올리고, 실패면 그대로 둬야 한다.
  final ValueChanged<bool>? onChanged;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = value && enabled;
    // 아이콘: disabled → iconMuted, active → accentDefault, inactive → iconMuted
    final iconColor = !enabled
        ? context.colors.iconMuted
        : active
            ? context.colors.accentDefault
            : context.colors.iconMuted;
    // 제목 텍스트: disabled → onSurfaceSubtle, active → accentOnContainer, inactive → onSurfaceMuted
    final titleColor = !enabled
        ? context.colors.onSurfaceSubtle
        : active
            ? context.colors.accentOnContainer
            : context.colors.onSurfaceMuted;
    // 서브타이틀: disabled → onSurfaceSubtle, active → accentDefault, inactive → onSurfaceSubtle
    final subtitleColor = !enabled
        ? context.colors.onSurfaceSubtle
        : active
            ? context.colors.accentDefault
            : context.colors.onSurfaceSubtle;
    final tap =
        (enabled && onChanged != null) ? () => onChanged!(!value) : null;

    return Semantics(
      toggled: value,
      label: '이 인용구만 잠그기',
      hint: value
          ? '잠금 켜짐. 본문이 암호화되어 본인만 볼 수 있어요.'
          : '잠금 꺼짐. 본문이 일반 인용구로 저장돼요.',
      child: Material(
        // active: 액센트 컨테이너 배경 / inactive: 일반 surface
      color: active ? context.colors.accentContainer : context.colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            // active: 액센트 테두리 / inactive: 기본 보더
            color: active ? context.colors.accentBorder : context.colors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s3,
              AppSpacing.s3,
              AppSpacing.s2,
              AppSpacing.s3,
            ),
            child: Row(
              children: [
                Icon(
                  active ? Icons.lock_outline : Icons.lock_open,
                  size: 22,
                  color: iconColor,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이 인용구만 잠그기',
                        style: textTheme.bodyMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active
                            ? '이 기기에서만 보여요 · 본인만 열람 가능'
                            : '본문을 암호화해 본인만 볼 수 있게 저장해요',
                        style: textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Switch.adaptive(
                    value: value,
                    onChanged: enabled ? onChanged : null,
                    activeThumbColor: context.colors.accentDefault,
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
