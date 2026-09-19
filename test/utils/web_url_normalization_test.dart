import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebUtil.normalizeSchemelessUrl', () {
    test('repairs URLs whose scheme separator survived', () {
      expect(
        WebUtil.normalizeSchemelessUrl('://imglf1.lf127.net/img/a.jpg'),
        'https://imglf1.lf127.net/img/a.jpg',
      );
    });

    test('repairs protocol-relative URLs', () {
      expect(
        WebUtil.normalizeSchemelessUrl('//imglf1.lf127.net/img/a.jpg'),
        'https://imglf1.lf127.net/img/a.jpg',
      );
    });

    test('leaves well-formed and relative URLs untouched', () {
      expect(
        WebUtil.normalizeSchemelessUrl('https://example.com/a.jpg'),
        'https://example.com/a.jpg',
      );
      expect(
        WebUtil.normalizeSchemelessUrl('http://example.com/a.jpg'),
        'http://example.com/a.jpg',
      );
      expect(
        WebUtil.normalizeSchemelessUrl('relative/a.jpg'),
        'relative/a.jpg',
      );
      expect(WebUtil.normalizeSchemelessUrl('/root/a.jpg'), '/root/a.jpg');
      expect(WebUtil.normalizeSchemelessUrl('#section'), '#section');
      expect(WebUtil.normalizeSchemelessUrl(''), '');
    });

    test('getBaseUrl never throws and tolerates missing source urls', () {
    // Post content renders without a source page url; the old implementation
    // built the literal "://" and Uri.parse threw FormatException for it.
    expect(WebUtil.getBaseUrl('').toString(), '');
    expect(() => WebUtil.getBaseUrl(null), returnsNormally);
    expect(
      WebUtil.getBaseUrl('https://www.lofter.com/post/abc').toString(),
      'https://www.lofter.com',
    );
  });

  test('resolveRelativeUrl no longer returns empty-scheme URLs', () {
      final resolved = WebUtil.resolveRelativeUrl(
        'https://www.lofter.com',
        '://imglf1.lf127.net/img/a.jpg',
      );
      expect(resolved.startsWith('https://'), isTrue);
      expect(() => Uri.parse(resolved), returnsNormally);
    });
  });
}
