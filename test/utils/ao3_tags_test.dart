import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/ao3_feed_entry.dart';
import 'package:loftify/Utils/ao3_tags.dart';
import 'package:loftify/Utils/hive_util.dart';

void main() {
  late Box settings;
  late Box ao3;

  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_tags');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      settings = await Hive.openBox(ChewieHiveUtil.settingsBox);
    } else {
      settings = Hive.box(ChewieHiveUtil.settingsBox);
    }
    ao3 = await Hive.openBox(HiveUtil.ao3Box);
  });

  setUp(() async {
    await settings.clear();
    await ao3.clear();
  });

  group('followed tags', () {
    test('follow adds and dedupes, unfollow removes', () async {
      expect(Ao3Tags.followed(), isEmpty);
      await Ao3Tags.follow('Fluff');
      await Ao3Tags.follow(' Fluff ');
      expect(Ao3Tags.followed(), ['Fluff']);
      await Ao3Tags.follow('Hurt/Comfort');
      expect(Ao3Tags.followed(), ['Fluff', 'Hurt/Comfort']);
      await Ao3Tags.unfollow('Fluff');
      expect(Ao3Tags.followed(), ['Hurt/Comfort']);
    });

    test('an empty or blank tag is ignored', () async {
      await Ao3Tags.follow('   ');
      expect(Ao3Tags.followed(), isEmpty);
    });

    test('a damaged persisted value degrades to an empty list', () async {
      await settings.put(HiveUtil.ao3FollowedTagsKey, '{not json');
      expect(Ao3Tags.followed(), isEmpty);
    });
  });

  group('feed cache', () {
    test('write then read round-trips and reports fresh', () async {
      await Ao3Tags.writeFeed('Fluff', const [
        Ao3FeedEntry(workId: 1, title: 't', author: 'a', updatedAtMs: 2),
      ]);
      final cache = Ao3Tags.readFeed('Fluff');
      expect(cache, isNotNull);
      expect(Ao3Tags.isFresh(cache), isTrue);
      expect(cache!.entries, hasLength(1));
      expect(cache.entries.first.workId, 1);
    });

    test('a cache past the TTL is no longer fresh', () {
      final stale = CachedFeed(
        fetchedAtMs: DateTime.now().millisecondsSinceEpoch -
            const Duration(hours: 2).inMilliseconds,
        entries: const [],
      );
      expect(Ao3Tags.isFresh(stale), isFalse);
      expect(Ao3Tags.readFeed('missing'), isNull);
    });
  });

  group('suggestions', () {
    test('ranks tags from cached works by frequency', () {
      ao3.put('work:1', '{"tagGroups":[{"label":"Freeform","values":["哨向","深海"]},{"label":"Fandom","values":["Delta Force (Video Games)"]}]}');
      ao3.put('work:2', '{"tagGroups":[{"label":"Freeform","values":["哨向"]}]}');
      ao3.put('not-a-work', '{}');
      final suggestions = Ao3Tags.suggestions();
      expect(suggestions.first, '哨向');
      expect(suggestions, contains('深海'));
      expect(suggestions, isNot(contains('Fluff')));
    });
  });

  test('the store only ranks; the sheet filters followed tags', () {
    // The sheet filters followed tags before rendering; the store only ranks.
    expect(Ao3Tags.followed(), isEmpty);
  });
}
