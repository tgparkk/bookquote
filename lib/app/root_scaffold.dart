// 책귀 — BottomNav 셸
//
// `StatefulShellRoute.indexedStack`의 `builder`가 받는 `navigationShell`을
// `body`로 두고, 하단에 NavigationBar를 그린다. 4개 브랜치(홈/서재/활동/내정보)와
// NavigationBar destination이 1:1 대응 — 인덱스 보정 없음.
//
// (구버전) 가운데 [+] '추가'는 라우트 아닌 sentinel이었으나, 인용구 추가 진입점이
// 여러 곳(홈 FAB·서재 [인용구] 탭 FAB·책 상세 등)에 있어 탭 한 칸을 '활동'으로 교체.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
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
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '활동',
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
