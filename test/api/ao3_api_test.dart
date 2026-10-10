import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Api/ao3_api.dart';
import 'package:loftify/Utils/ao3_config.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'dart:io';

const _export = r'''
<html><body>
<div id="preface">
  <div class="meta">
    <dl class="tags"><dt>Rating:</dt><dd><a href="/tags/Teen">Teen And Up Audiences</a></dd>
    <dt>Stats:</dt><dd>Words: 42</dd></dl>
    <h1>Test Work</h1>
    <div class="byline">by <a href="/users/someone">someone</a></div>
  </div>
</div>
<div id="chapters" class="userstuff"><div class="userstuff"><p>Body.</p></div></div>
</body></html>
''';

const _blockPage = '<html><head><title>Shields are up! | Archive of Our Own'
    '</title></head><body><h1>Shields are up!</h1></body></html>';

Ao3FetchResult _ok(String body, {String finalUrl = ''}) => Ao3FetchResult(
    statusCode: 200,
    body: body,
    finalUrl: finalUrl.isEmpty
        ? 'https://archiveofourown.org/downloads/5/Work.html'
        : finalUrl);

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_api');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
    if (!Hive.isBoxOpen(HiveUtil.ao3Box)) {
      await Hive.openBox(HiveUtil.ao3Box);
    }
  });

  const enabled = Ao3Config(enabled: true);

  test('builds the export url', () {
    expect(Ao3Api.exportUrl(12345).toString(),
        'https://archiveofourown.org/downloads/12345/Work.html');
  });

  test('parses a 200 export', () async {
    final work = await Ao3Api.fetchWork(5,
        config: enabled, fetcher: (uri) async => _ok(_export));
    expect(work.title, 'Test Work');
    expect(work.author, 'someone');
    expect(work.words, 42);
    expect(work.chapters, hasLength(1));
  });

  test('403 is a block, not a retry', () async {
    var calls = 0;
    await expectLater(
      Ao3Api.fetchWork(5, config: enabled, fetcher: (uri) async {
        calls++;
        return const Ao3FetchResult(statusCode: 403, body: _blockPage);
      }),
      throwsA(isA<Ao3Exception>()
          .having((e) => e.failure, 'failure', Ao3Failure.blocked)
          .having((e) => e.retryable, 'retryable', isFalse)),
    );
    expect(calls, 1);
  });

  test('a block page served as 200 is still blocked', () async {
    await expectLater(
      Ao3Api.fetchWork(5, config: enabled, fetcher: (uri) async => _ok(_blockPage)),
      throwsA(isA<Ao3Exception>()
          .having((e) => e.failure, 'failure', Ao3Failure.blocked)),
    );
  });

  test('404 is not found', () async {
    await expectLater(
      Ao3Api.fetchWork(5,
          config: enabled,
          fetcher: (uri) async =>
              const Ao3FetchResult(statusCode: 404, body: 'nope')),
      throwsA(isA<Ao3Exception>()
          .having((e) => e.failure, 'failure', Ao3Failure.notFound)),
    );
  });

  test('a login redirect asks for sign-in', () async {
    await expectLater(
      Ao3Api.fetchWork(5, config: enabled, fetcher: (uri) async => _ok(
          'login please',
          finalUrl:
              'https://archiveofourown.org/users/login?restricted=true')),
      throwsA(isA<Ao3Exception>()
          .having((e) => e.failure, 'failure', Ao3Failure.loginRequired)),
    );
  });

  test('200 that is not a work export is classified', () async {
    await expectLater(
      Ao3Api.fetchWork(5,
          config: enabled,
          fetcher: (uri) async => _ok('<html><body>hi</body></html>')),
      throwsA(isA<Ao3Exception>()
          .having((e) => e.failure, 'failure', Ao3Failure.notAWork)),
    );
  });

  test('network failures retry, then succeed', () async {
    var calls = 0;
    final work = await Ao3Api.fetchWork(5, config: enabled, fetcher: (uri) async {
      calls++;
      if (calls < 3) {
        throw const Ao3Exception(Ao3Failure.timeout);
      }
      return _ok(_export);
    });
    expect(calls, 3);
    expect(work.title, 'Test Work');
  });

  test('retries stop at the attempt limit', () async {
    var calls = 0;
    await expectLater(
      Ao3Api.fetchWork(5, config: enabled, attempts: 2, fetcher: (uri) async {
        calls++;
        throw const Ao3Exception(Ao3Failure.network);
      }),
      throwsA(isA<Ao3Exception>()
          .having((e) => e.failure, 'failure', Ao3Failure.network)),
    );
    expect(calls, 2);
  });

  test('a disabled feature never touches the network', () async {
    var calls = 0;
    await expectLater(
      Ao3Api.fetchWork(5,
          config: const Ao3Config(enabled: false), fetcher: (uri) async {
        calls++;
        return _ok(_export);
      }),
      throwsA(isA<Ao3Exception>()
          .having((e) => e.failure, 'failure', Ao3Failure.disabled)),
    );
    expect(calls, 0);
  });

  group('Ao3Config.findProxyValue', () {
    test('accepts host:port and urls', () {
      expect(Ao3Config.findProxyValue('127.0.0.1:7890'), 'PROXY 127.0.0.1:7890');
      expect(Ao3Config.findProxyValue('http://127.0.0.1:7890'),
          'PROXY 127.0.0.1:7890');
      expect(Ao3Config.findProxyValue('socks5://127.0.0.1:1080'),
          'SOCKS5 127.0.0.1:1080');
      expect(Ao3Config.findProxyValue('  '), isNull);
      expect(Ao3Config.findProxyValue('http://'), isNull);
    });
  });
}
