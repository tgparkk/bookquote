import 'package:bookquote/features/follow/state/follow_providers.dart';
import 'package:bookquote/features/me/me_screen.dart';
import 'package:bookquote/features/me/state/me_providers.dart';
import 'package:bookquote/features/profile/data/profile_repository.dart';
import 'package:bookquote/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// url_launcher fake — 실제 플랫폼 채널은 테스트에서 Future가 완료되지 않아
/// (호스트에 구현체 미등록) launch 흐름 검증이 불가능하다. 호출 URL을 기록하고
/// 항상 실패를 돌려줘 폴백 경로까지 검증한다.
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return false;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpMe(
    WidgetTester tester, {
    required bool loggedIn,
    String? email,
    String? displayName,
  }) async {
    // 섹션이 많아 기본 600px 뷰포트엔 다 안 들어간다 — 한 화면에 담기게 키운다.
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meSessionInfoProvider
              .overrideWithValue((loggedIn: loggedIn, email: email)),
          myProfileProvider.overrideWith(
            (ref) => displayName == null
                ? null
                : Profile(
                    id: 'u',
                    displayName: displayName,
                    isLibraryPublic: false,
                  ),
          ),
          myQuoteCountProvider.overrideWith((ref) => 12),
          myBookCountProvider.overrideWith((ref) => 3),
          myFollowingCountProvider.overrideWith((ref) => 5),
          appVersionProvider
              .overrideWith((ref) => (version: '1.0.0', buildNumber: '1')),
        ],
        child: const MaterialApp(home: MeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('로그인 상태 — 프로필·내 데이터·설정·정보·계정 섹션이 모두 보인다', (tester) async {
    await pumpMe(tester, loggedIn: true, email: 'reader@example.com');

    // 프로필
    expect(find.text('reader@example.com'), findsOneWidget);
    expect(find.text('로그인됨'), findsOneWidget);
    // 내 데이터
    expect(find.text('내 데이터'), findsOneWidget);
    expect(find.text('12개'), findsOneWidget);
    expect(find.text('3권'), findsOneWidget);
    expect(find.text('Markdown으로 내보내기'), findsOneWidget);
    // 설정
    expect(find.text('시스템 설정'), findsOneWidget);
    // 알림 설정 진입 타일 (PR-PB.2 — 비활성 '곧 추가될 기능' 대체)
    expect(find.text('알림'), findsOneWidget);
    // 정보
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    expect(find.text('문의하기'), findsOneWidget);
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    // 계정
    expect(find.widgetWithText(OutlinedButton, '로그아웃'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '회원 탈퇴'), findsOneWidget);
    // 친구 — PR18-B에서 V1.0 활성화 (DECISIONS 2026-05-18)
    expect(find.text('친구 찾기'), findsOneWidget);
    // 내 팔로잉 명단 진입 타일 (2026-05-21 매니저 회의 — V1.0)
    expect(find.text('내 친구'), findsOneWidget);
    expect(find.text('5명'), findsOneWidget);
  });

  testWidgets('카카오 로그인(이메일 없음) — 닉네임이 대표로 보이고 "이메일 없음"이 안 뜬다',
      (tester) async {
    await pumpMe(tester, loggedIn: true, displayName: '독서가');

    // 대표 줄에 닉네임이 보인다(헤더 + 공개 닉네임 타일).
    expect(find.text('독서가'), findsWidgets);
    // 이메일이 없어도 "이메일 없음" 같은 빈 상태 문구는 뜨지 않는다.
    expect(find.text('이메일 없음'), findsNothing);
    // 보조 줄은 '로그인됨'.
    expect(find.text('로그인됨'), findsOneWidget);
  });

  testWidgets('비로그인 상태(도달 시) — 내 데이터 숨김 + [로그인하기], 회원 탈퇴 없음', (tester) async {
    await pumpMe(tester, loggedIn: false);

    expect(find.text('로그인 정보 없음'), findsOneWidget);
    expect(find.text('내 데이터'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '로그인하기'), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsNothing);
    // 설정·정보 섹션은 그대로
    expect(find.text('이용약관'), findsOneWidget);
  });

  testWidgets('앱 버전 타일 탭 → market 시도 후 웹 폴백, 모두 실패면 안내 스낵바', (tester) async {
    final fake = _FakeUrlLauncher();
    final original = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = fake;
    addTearDown(() => UrlLauncherPlatform.instance = original);

    await pumpMe(tester, loggedIn: true, email: 'reader@example.com');

    final versionTile = find.widgetWithText(ListTile, '앱 버전');
    expect(versionTile, findsOneWidget);
    await tester.ensureVisible(versionTile);
    await tester.pumpAndSettle();
    await tester.tap(versionTile);
    await tester.pumpAndSettle();

    // market:// 먼저, 실패 시 Play 웹 URL 폴백 순서로 시도한다.
    expect(fake.launched, [
      'market://details?id=io.github.tgparkk.bookquote',
      'https://play.google.com/store/apps/details?id=io.github.tgparkk.bookquote',
    ]);
    // 둘 다 실패하면 크래시 없이 안내 스낵바.
    expect(find.text('스토어를 열 수 없어요. 잠시 후 다시 시도해주세요.'), findsOneWidget);
  });

  testWidgets('회원 탈퇴 탭 → 영구 삭제 경고 + 내보내기 권유 다이얼로그(1단계)', (tester) async {
    await pumpMe(tester, loggedIn: true, email: 'reader@example.com');

    final deleteBtn = find.widgetWithText(TextButton, '회원 탈퇴');
    await tester.ensureVisible(deleteBtn);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('되돌릴 수 없어요'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '내보내고 탈퇴'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '계속'), findsOneWidget);
  });
}
