import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Models/ao3_work.dart';
import 'package:loftify/Utils/ao3_config.dart';
import 'package:loftify/Utils/ao3_store.dart';
import 'package:loftify/Utils/hive_util.dart';

Ao3Work _work(int id, {String title = 'Work', int chapters = 1, String body = 'Body'}) =>
    Ao3Work(
      id: id,
      title: title,
      author: 'author',
      words: 100 * id,
      chapters: List.generate(
        chapters,
        (index) => Ao3Chapter(
          index: index + 1,
          title: 'Chapter ' + (index + 1).toString(),
          bodyHtml: '<p>' + body + '</p>',
        ),
      ),
    );

void main() {
  late Box box;

  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_store');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
    box = await Hive.openBox(HiveUtil.ao3Box);
  });

  setUp(() async {
    await box.clear();
    Ao3Config.saveCacheLimit(50);
  });

  test('round-trips a cached work', () async {
    final store = Ao3Store(box: box);
    await store.save(_work(1, title: 'Cached', chapters: 3));

    final restored = store.read(1)!;
    expect(restored.title, 'Cached');
    expect(restored.chapters, hasLength(3));
    expect(restored.chapters.last.title, 'Chapter 3');
    expect(store.isCached(1), isTrue);

    final entry = store.entry(1)!;
    expect(entry.title, 'Cached');
    expect(entry.chapterCount, 3);
    expect(entry.cached, isTrue);
  });

  test('lists entries newest read first', () async {
    var clock = 1000;
    final store = Ao3Store(box: box, now: () => clock);
    await store.save(_work(1));
    clock = 2000;
    await store.save(_work(2));
    clock = 1500;
    await store.updateProgress(1, 1);
    expect(store.entries().map((e) => e.id).toList(), [2, 1]);
  });

  test('keeps reading progress per work', () async {
    final store = Ao3Store(box: box);
    await store.save(_work(7, chapters: 5));
    await store.updateProgress(7, 4);
    expect(store.entry(7)!.chapterIndex, 4);
    // Re-saving the work must not reset progress.
    await store.save(_work(7, chapters: 5, body: 'Updated'));
    expect(store.entry(7)!.chapterIndex, 4);
  });

  test('remove drops the shelf row and the body', () async {
    final store = Ao3Store(box: box);
    await store.save(_work(3));
    await store.remove(3);
    expect(store.entry(3), isNull);
    expect(store.read(3), isNull);
    expect(store.entries(), isEmpty);
  });

  test('clear empties the shelf', () async {
    final store = Ao3Store(box: box);
    await store.save(_work(1));
    await store.save(_work(2));
    await store.clear();
    expect(store.entries(), isEmpty);
    expect(store.cachedBytes(), 0);
  });

  test('a work over the cache limit keeps its row but no body', () async {
    final store = Ao3Store(box: box, maxCachedBytes: 200);
    await store.save(_work(9, body: 'x' * 500));
    final entry = store.entry(9)!;
    expect(entry.cached, isFalse);
    expect(entry.title, 'Work');
    expect(store.read(9), isNull);
  });

  test('prunes the least recently read cached works on save', () async {
    Ao3Config.saveCacheLimit(2);
    var clock = 100;
    final store = Ao3Store(box: box, now: () => clock);
    for (final id in [1, 2, 3]) {
      clock += 100;
      await store.save(_work(id));
    }

    // Three saves with a limit of two: the oldest body is dropped as soon as
    // the third one lands.
    expect(store.entries().where((e) => e.cached).map((e) => e.id).toSet(),
        {2, 3});
    // The pruned work keeps its shelf row so it can be re-fetched later.
    expect(store.entry(1), isNotNull);
    expect(store.entry(1)!.cached, isFalse);
    expect(store.read(1), isNull);
    expect(store.read(3), isNotNull);

    // Reading an evicted work updates recency but does not silently re-cache
    // a body the app no longer has.
    clock += 100;
    await store.updateProgress(1, 2);
    expect(store.entries().first.id, 1);
    expect(store.entry(1)!.cached, isFalse);
    expect(store.entry(1)!.chapterIndex, 2);

    // Saving it again (a fresh fetch) makes room by evicting the new LRU.
    clock += 100;
    await store.save(_work(1));
    expect(store.entries().where((e) => e.cached).map((e) => e.id).toSet(),
        {1, 3});
    expect(store.read(2), isNull);
  });
}
