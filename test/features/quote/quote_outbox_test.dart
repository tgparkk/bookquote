// 아웃박스 동시 flush race + FK 위반 분리 처리 (PR14-A: B1·B2).
//
// - B1: 같은 SharedPreferences를 공유하는 두 호출이 동시에 flush()로 진입해도
//   같은 항목이 두 번 INSERT되지 않아야 한다 (static _isFlushing 가드).
// - B2: FK 위반(QuoteRepositoryException code='FK_VIOLATION')은 영구 실패로
//   분류해 큐에서 폐기(discarded). 그 외 실패는 큐에 남겨 재시도(remaining).
//
// 테스트는 uid를 명시 전달해 supabase 인스턴스 의존을 회피한다 — production은
// 동일 메서드를 uid 없이 호출해 currentUser?.id로 가져온다.

import 'package:bookquote/features/quote/data/quote_outbox.dart';
import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uid = 'u1';

/// createQuote 호출 횟수를 카운트하고 behavior에 따라 성공/예외 반환.
class _CountingRepo implements QuoteRepository {
  _CountingRepo(this.behavior);

  final Future<Quote> Function(QuoteInput input, int callIndex) behavior;

  int calls = 0;

  @override
  Future<Quote> createQuote(QuoteInput input) async {
    final i = calls++;
    return behavior(input, i);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected ${invocation.memberName} call');
}

Quote _makeQuote(String id, String text) => Quote(
      id: id,
      userId: _uid,
      text: text,
      moods: const <QuoteMood>[],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

QuoteInput _makeInput(String text) =>
    QuoteInput(text: text, source: QuoteSource.manual);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('동시 flush 호출은 같은 항목을 두 번 INSERT하지 않는다 (B1 race)',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(prefs);
    await outbox.enqueue(_makeInput('첫번째'), _uid);
    await outbox.enqueue(_makeInput('두번째'), _uid);

    final repo = _CountingRepo(
      (input, i) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _makeQuote('q$i', input.text);
      },
    );

    // 같은 prefs를 공유하는 두 outbox 인스턴스 (invalidate 시뮬레이션).
    final outboxA = QuoteOutbox(prefs);
    final outboxB = QuoteOutbox(prefs);
    final results = await Future.wait([
      outboxA.flush(repo, uid: _uid),
      outboxB.flush(repo, uid: _uid),
    ]);

    expect(repo.calls, 2, reason: '중복 INSERT 방지');
    final totalSent = results[0].sent + results[1].sent;
    expect(totalSent, 2);
    expect(QuoteOutbox(prefs).pending(_uid), isEmpty);
  });

  test('FK 위반 항목은 discarded로 분류되고 큐에서 제거된다 (B2)', () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(prefs);
    await outbox.enqueue(_makeInput('정상'), _uid);
    await outbox.enqueue(_makeInput('FK위반'), _uid);
    await outbox.enqueue(_makeInput('일시적실패'), _uid);

    final repo = _CountingRepo((input, i) async {
      if (input.text == 'FK위반') {
        throw QuoteRepositoryException('FK_VIOLATION', 'book_id not found');
      }
      if (input.text == '일시적실패') {
        throw Exception('network');
      }
      return _makeQuote('q$i', input.text);
    });

    final result = await outbox.flush(repo, uid: _uid);
    expect(result.sent, 1);
    expect(result.discarded, 1);
    expect(result.remaining, 1);

    final pending = QuoteOutbox(prefs).pending(_uid);
    expect(pending.length, 1);
    expect(pending.single.text, '일시적실패',
        reason: 'FK는 폐기, 일시 실패는 큐에 남음');
  });

  test('연속 flush 두 번째 호출은 같은 데이터를 다시 보내지 않는다 (B1 직렬화)',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(prefs);
    await outbox.enqueue(_makeInput('단건'), _uid);

    final repo = _CountingRepo(
      (input, i) async => _makeQuote('q$i', input.text),
    );

    await outbox.flush(repo, uid: _uid);
    await outbox.flush(repo, uid: _uid);

    expect(repo.calls, 1, reason: '첫 flush로 큐 비워짐 → 두 번째는 no-op');
  });

  test('FK 위반만 있는 경우 큐가 완전히 비워진다 (B2)', () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(prefs);
    await outbox.enqueue(_makeInput('FK1'), _uid);
    await outbox.enqueue(_makeInput('FK2'), _uid);

    final repo = _CountingRepo((input, i) async {
      throw QuoteRepositoryException('FK_VIOLATION', 'gone');
    });

    final result = await outbox.flush(repo, uid: _uid);
    expect(result.discarded, 2);
    expect(result.remaining, 0);
    expect(QuoteOutbox(prefs).pending(_uid), isEmpty);
  });
}
