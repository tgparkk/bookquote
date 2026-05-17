// QuoteDraftStore — savedAt 래퍼 v2 포맷 + 구 포맷 호환 (PR14-E F5).
// load는 supabase 의존이라 uid를 명시 전달해 회피.

import 'dart:convert';

import 'package:bookquote/features/quote/data/quote_draft.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uid = 'u1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('save→load round-trip — input + savedAt 그대로', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = QuoteDraftStore(prefs);
    final saved = DateTime.utc(2026, 5, 15, 9, 30);

    await store.save(
      const QuoteInput(text: '어느 봄날의 한 줄', page: 42),
      _uid,
      saved,
    );

    final loaded = store.load(_uid);
    expect(loaded, isNotNull);
    expect(loaded!.input.text, '어느 봄날의 한 줄');
    expect(loaded.input.page, 42);
    expect(loaded.savedAt, saved);
  });

  test('savedAt 생략 시 현재시각으로 기록 — 5초 안', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = QuoteDraftStore(prefs);
    final before = DateTime.now();

    await store.save(const QuoteInput(text: '본문'), _uid);

    final loaded = store.load(_uid)!;
    expect(
      loaded.savedAt.difference(before).inSeconds.abs() < 5,
      isTrue,
      reason: 'savedAt이 현재 시각 근처에 기록되어야 함',
    );
  });

  test('구 포맷(QuoteInput JSON 단독) 호환 — savedAt은 현재로 폴백', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'quote_draft_v1:$_uid': jsonEncode(<String, dynamic>{
        'text': '구 포맷 본문',
        'page': 1,
        'source': 'manual',
        'moods': <String>[],
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final store = QuoteDraftStore(prefs);

    final loaded = store.load(_uid);
    expect(loaded, isNotNull, reason: '구 포맷도 파싱 성공');
    expect(loaded!.input.text, '구 포맷 본문');
    expect(loaded.input.page, 1);
  });

  test('손상된 JSON은 null', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'quote_draft_v1:$_uid': '{not valid json',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = QuoteDraftStore(prefs);

    expect(store.load(_uid), isNull);
  });

  test('clear 후 load = null', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = QuoteDraftStore(prefs);
    await store.save(const QuoteInput(text: '본문'), _uid);
    expect(store.load(_uid), isNotNull);
    await store.clear(_uid);
    expect(store.load(_uid), isNull);
  });
}
