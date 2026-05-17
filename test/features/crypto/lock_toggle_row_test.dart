// LockToggleRow 위젯 테스트 (PR16-C-1).
//
// 시각(아이콘·보조 텍스트)과 상호작용(탭 → onChanged) 검증. 비활성 상태에서
// 탭해도 콜백이 안 오는지(우발 잠금 차단).

import 'package:bookquote/features/crypto/presentation/lock_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({
    required bool value,
    ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LockToggleRow(
          value: value,
          onChanged: onChanged,
          enabled: enabled,
        ),
      ),
    );
  }

  testWidgets('OFF 상태 — lock_open 아이콘 + 평문 안내', (tester) async {
    await tester.pumpWidget(wrap(value: false, onChanged: (_) {}));
    expect(find.byIcon(Icons.lock_open), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.textContaining('암호화해 본인만'), findsOneWidget);
  });

  testWidgets('ON 상태 — lock_outline 아이콘 + 이 기기 안내', (tester) async {
    await tester.pumpWidget(wrap(value: true, onChanged: (_) {}));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_open), findsNothing);
    expect(find.textContaining('이 기기에서만'), findsOneWidget);
  });

  testWidgets('탭 → onChanged(!value)', (tester) async {
    bool? lastValue;
    await tester.pumpWidget(wrap(value: false, onChanged: (v) => lastValue = v));
    await tester.tap(find.byType(LockToggleRow));
    await tester.pump();
    expect(lastValue, isTrue);
  });

  testWidgets('Switch 자체 탭도 onChanged 호출 — value 반전', (tester) async {
    bool? lastValue;
    await tester.pumpWidget(wrap(value: true, onChanged: (v) => lastValue = v));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(lastValue, isFalse);
  });

  testWidgets('enabled=false — 탭해도 onChanged 미호출', (tester) async {
    bool called = false;
    await tester.pumpWidget(wrap(
      value: false,
      enabled: false,
      onChanged: (_) => called = true,
    ));
    await tester.tap(find.byType(LockToggleRow));
    await tester.pump();
    expect(called, isFalse);
  });

  testWidgets('onChanged=null — Switch 비활성', (tester) async {
    await tester.pumpWidget(wrap(value: false, onChanged: null));
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNull);
  });
}
