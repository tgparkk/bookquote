import 'package:bookquote/features/book/domain/html_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('알라딘 설명의 &lt;&gt; → 꺾쇠', () {
    expect(
      decodeHtmlEntities('판매되어 &lt;이방인&gt;을 바로 뒤쫓는'),
      '판매되어 <이방인>을 바로 뒤쫓는',
    );
  });

  test('이름·10진·16진 엔티티', () {
    expect(decodeHtmlEntities('&quot;a&quot; &amp; b&#39;s &#x27;c&#x27;'),
        '"a" & b\'s \'c\'');
  });

  test('이중 해석 안 함 · 모르는 엔티티는 유지', () {
    expect(decodeHtmlEntities('&amp;lt;'), '&lt;');
    expect(decodeHtmlEntities('A &foo; B'), 'A &foo; B');
    expect(decodeHtmlEntities('R&D 팀'), 'R&D 팀');
  });
}
