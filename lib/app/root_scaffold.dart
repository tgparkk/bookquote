// 책귀 — BottomNav 셸
//
// `StatefulShellRoute.indexedStack`의 `builder`가 받는 `navigationShell`을
// `body`로 두고, 하단에 NavigationBar를 그린다. 가운데 [+] 슬롯은 실제
// 라우트가 아닌 sentinel — 탭하면 root navigator에 `/quote/new`를 push한다.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// `[+]` 가상 탭의 시각적 인덱스. NavigationBar destination 순서와 일치해야 함.
  static const int _createSentinelIndex = 2;

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == _createSentinelIndex) {
      context.push('/quote/new');
      return;
    }

    // sentinel을 건너뛴 실제 branch 인덱스 매핑
    final branchIndex = index < _createSentinelIndex ? index : index - 1;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int _selectedNavBarIndex() {
    // navigationShell.currentIndex는 0,1,2 (홈/서재/내정보 branch). NavBar 슬롯
    // 인덱스(2번이 sentinel)와 어긋나므로 보정.
    final shellIndex = navigationShell.currentIndex;
    return shellIndex < _createSentinelIndex ? shellIndex : shellIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavBarIndex(),
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '서재',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: '추가',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
      ),
    );
  }
}
