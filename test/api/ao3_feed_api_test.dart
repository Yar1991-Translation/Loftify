import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Api/ao3_api.dart';
import 'package:loftify/Api/ao3_feed_api.dart';
import 'package:loftify/Utils/ao3_config.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

const String listing = '''
<ol class="work index group">
<li id="work_111" class="work blurb group" role="article">
<div class="header module">
<h4 class="heading"><a href="/works/111">Cached work</a>
by <a rel="author" href="/users/w/pseuds/w">writer</a></h4>
<p class="datetime">02 Jan 2026</p>
</div>
</li>
</ol>
''';

Ao3Fetcher _fetcher(int status, String body) {
  return (uri) async => Ao3FetchResult(statusCode: status, body: body);
}

Ao3Config _config() {
  Ao3Config.saveEnabled(true);
  return Ao3Config.load();
}

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_feed_api');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  group('Ao3FeedApi URIs', () {
    test('tag paths use the AO3 star forms', () {
      expect(Ao3FeedApi.tagPath('Hurt/Comfort'), 'Hurt*s*Comfort');
      expect(Ao3FeedApi.tagPath('Rock & Roll'), 'Rock%20*a*%20Roll');
      expect(Ao3FeedApi.tagPath('哨向'), '%E5%93%A8%E5%90%91');
      expect(
        Ao3FeedApi.tagPath('Kai "D-Wolf" Silva'),
        'Kai%20%22D-Wolf%22%20Silva',
      );
      // A plain tag passes through untouched.
      expect(Ao3FeedApi.tagPath('Fluff'), 'Fluff');
    });

    test('tag listing keeps the encoded tag and adult gate', () {
      final uri = Ao3FeedApi.tagWorksUri('Hurt/Comfort');
      expect(uri.toString(),
          contains('https://archiveofourown.org/tags/Hurt*s*Comfort/works'));
      expect(uri.queryParameters['view_adult'], 'true');
      expect(uri.queryParameters.containsKey('page'), isFalse);
    });

    test('tag listing carries the page parameter from page two', () {
      final uri = Ao3FeedApi.tagWorksUri('Fluff', page: 2);
      expect(uri.queryParameters['page'], '2');
    });

    test('search escapes the bracketed form parameters', () {
      final uri = Ao3FeedApi.searchWorksUri('deep sea', page: 3);
      expect(uri.path, '/works/search');
      expect(uri.queryParameters['work_search[query]'], 'deep sea');
      expect(uri.queryParameters['work_search[sort_id]'], '_score');
      expect(uri.queryParameters['page'], '3');
    });
  });

  group('Ao3FeedApi fetching', () {
    test('parses listings from the injected fetcher', () async {
      final entries = await Ao3FeedApi.fetchTagWorks(
        'Fluff',
        fetcher: _fetcher(200, listing),
        config: _config(),
      );
      expect(entries, hasLength(1));
      expect(entries.single.workId, 111);
      expect(entries.single.title, 'Cached work');
    });

    test('search results use the same parser', () async {
      Uri? seen;
      final entries = await Ao3FeedApi.searchWorks(
        'deep sea',
        fetcher: (uri) async {
          seen = uri;
          return Ao3FetchResult(statusCode: 200, body: listing);
        },
        config: _config(),
      );
      expect(entries, hasLength(1));
      expect(seen!.path, '/works/search');
    });

    test('the adult gate is a blocked request, not an empty list', () {
      expect(
        Ao3FeedApi.fetchTagWorks(
          'Fluff',
          fetcher: _fetcher(
            200,
            '<p>This work could have adult content.</p>',
          ),
          config: _config(),
        ),
        throwsA(
          isA<Ao3Exception>().having(
            (e) => e.failure,
            'failure',
            Ao3Failure.blocked,
          ),
        ),
      );
    });

    test('the feature switch wins over any network activity', () async {
      var calls = 0;
      await expectLater(
        Ao3FeedApi.fetchTagWorks(
          'Fluff',
          fetcher: (uri) async {
            calls++;
            return Ao3FetchResult(statusCode: 200, body: listing);
          },
          config: () {
            Ao3Config.saveEnabled(false);
            return Ao3Config.load();
          }(),
        ),
        throwsA(
          isA<Ao3Exception>().having(
            (e) => e.failure,
            'failure',
            Ao3Failure.disabled,
          ),
        ),
      );
      expect(calls, 0);
    });
  });
}
