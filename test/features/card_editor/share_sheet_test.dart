// 카드 공유 시트 — 4버튼 + 안내 카피 렌더 검증.
// V1은 4버튼 모두 share_plus OS 시트로 통합되므로 onTap을 실제 호출하지 않고
// 위젯 트리만 검증한다 — 플랫폼 채널 모킹은 V1.1.

import 'package:bookquote/features/card_editor/presentation/widgets/share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  testWidgets('showCardShareSheet — 4버튼 + 안내 카피 모두 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCardShareSheet(
                  context: context,
                  file: XFile('dummy.png'),
                  shareText: '인용구 본문',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('카카오톡 단톡방으로 보내기'), findsOneWidget);
    expect(find.text('인스타그램 스토리 (9:16)'), findsOneWidget);
    expect(find.text('이미지 저장'), findsOneWidget);
    expect(find.text('다른 앱으로 공유'), findsOneWidget);
    expect(find.text('저장 권한이 없어도 공유는 그대로 할 수 있어요.'), findsOneWidget);
  });
}
