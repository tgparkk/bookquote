// 알라딘 API는 책 설명에 HTML 엔티티(`&lt;이방인&gt;`)를 그대로 담아 보낸다.
// 저장 경로(Edge Function → upsert_book)는 원문을 보존하므로 표시 직전에 푼다 —
// 이미 저장된 책도 함께 고쳐진다(2026-10-10 기준 51권 중 8권 설명에 &lt;/&gt;).

const _named = {
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'middot': '·',
  'amp': '&',
};

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);');

/// 이름/숫자 HTML 엔티티를 문자로 바꾼다. 모르는 이름은 그대로 둔다.
/// 한 번만 훑으므로 `&amp;lt;`는 `&lt;`가 된다(이중 해석 안 함).
String decodeHtmlEntities(String input) {
  if (!input.contains('&')) return input;
  return input.replaceAllMapped(_entity, (m) {
    final body = m[1]!;
    if (body.startsWith('#')) {
      final code = body.startsWith('#x') || body.startsWith('#X')
          ? int.tryParse(body.substring(2), radix: 16)
          : int.tryParse(body.substring(1));
      if (code == null || code > 0x10FFFF) return m[0]!;
      return String.fromCharCode(code);
    }
    return _named[body] ?? m[0]!;
  });
}
