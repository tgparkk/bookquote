// "내 정보" 화면 providers — 내 데이터 카운트 + 앱 버전.
//
// 카운트는 autoDispose(화면 떠나면 해제, 다시 들어오면 최신값 재조회). 갱신이 필요하면
// `ref.invalidate(myQuoteCountProvider)` 등. 앱 버전은 한 번 읽으면 안 바뀌므로 비-autoDispose.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/auth_state_provider.dart';
import '../../book/data/book_repository.dart';
import '../../quote/data/quote_repository.dart';

/// "내 정보" 화면이 쓰는 세션 요약 — Session 전체를 들고 다니지 않게 추려서 노출
/// (테스트에서 이 한 줄만 override하면 로그인/비로그인 UI를 다 검증할 수 있다).
typedef MeSessionInfo = ({bool loggedIn, String? email});

final meSessionInfoProvider = Provider<MeSessionInfo>((ref) {
  final session = ref.watch(currentSessionProvider);
  return (loggedIn: session != null, email: session?.user.email);
});

/// 내가 모은 인용구 총 개수.
final myQuoteCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.read(quoteRepositoryProvider).countMyQuotes();
});

/// 내 서재 책 권수.
final myBookCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.read(bookRepositoryProvider).countMyLibrary();
});

/// 앱 버전/빌드 번호 — "정보" 섹션 표시용.
final appVersionProvider =
    FutureProvider<({String version, String buildNumber})>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return (version: info.version, buildNumber: info.buildNumber);
});
