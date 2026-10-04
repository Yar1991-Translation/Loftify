import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Utils/ao3_config.dart';
import 'package:loftify/Utils/clipboard_link_controller.dart';
import 'package:loftify/Utils/clipboard_snapshot.dart';
import 'package:loftify/Utils/uri_util.dart';

ClipboardSnapshot _snapshot(String text) => ClipboardSnapshot(
      text: text,
      platform: 'test',
      observedAtMs: 1,
    );

void main() {
  setUpAll(() async {
    final directory = Directory('build/test_hive/ao3_links');
    await directory.create(recursive: true);
    Hive.init(directory.absolute.path);
    if (!Hive.isBoxOpen(ChewieHiveUtil.settingsBox)) {
      await Hive.openBox(ChewieHiveUtil.settingsBox);
    }
  });

  setUp(() async {
    await Hive.box(ChewieHiveUtil.settingsBox).clear();
    Ao3Config.saveClipboardPrompt(false);
  });

  group('extractAo3WorkId', () {
    test('reads work ids from every supported link shape', () {
      expect(
          LoftifyUriUtil.extractAo3WorkId(
              'https://archiveofourown.org/works/12345'),
          12345);
      expect(
          LoftifyUriUtil.extractAo3WorkId(
              'https://archiveofourown.org/works/12345/chapters/67890'),
          12345);
      expect(
          LoftifyUriUtil.extractAo3WorkId(
              'https://archiveofourown.org/works/12345?view_adult=true'),
          12345);
      expect(
          LoftifyUriUtil.extractAo3WorkId(
              'https://archiveofourown.org/downloads/12345/Work.html'),
          12345);
      expect(LoftifyUriUtil.extractAo3WorkId('https://ao3.org/works/777'), 777);
    });

    test('ignores non-work pages and other hosts', () {
      expect(
          LoftifyUriUtil.extractAo3WorkId(
              'https://archiveofourown.org/users/threerings'),
          isNull);
      expect(
          LoftifyUriUtil.extractAo3WorkId(
              'https://archiveofourown.org/tags/Harry%20Potter'),
          isNull);
      expect(
          LoftifyUriUtil.extractAo3WorkId('https://lofter.com/post/abc'), isNull);
      expect(LoftifyUriUtil.extractAo3WorkId(''), isNull);
      expect(LoftifyUriUtil.extractAo3WorkId('just some text'), isNull);
    });

    test('finds a link inside copied share text', () {
      const shared = 'Unquencable - threerings\n'
          'https://archiveofourown.org/works/12345\n'
          'Posted originally on the Archive of Our Own.';
      expect(LoftifyUriUtil.extractAo3WorkId(shared), 12345);
      expect(LoftifyUriUtil.extractAo3Url(shared),
          'https://archiveofourown.org/works/12345');
    });

    test('isAo3WorkUrl matches the reader entry point', () {
      expect(LoftifyUriUtil.isAo3WorkUrl('https://archiveofourown.org/works/1'),
          isTrue);
      expect(
          LoftifyUriUtil.isAo3WorkUrl('https://example.com/works/1'), isFalse);
    });
  });

  group('AO3 clipboard prompt', () {
    test('the shared recogniser leaves AO3 links alone', () {
      // The opt-in gate lives in the controller, so the pure recogniser keeps
      // returning null for AO3.
      expect(
        LoftifyUriUtil.extractSupportedClipboardUrl(
            'https://archiveofourown.org/works/12345'),
        isNull,
      );
    });

    test('stays silent while the setting is off', () async {
      var prompts = 0;
      final controller = ClipboardLinkController(
        canPrompt: () => true,
        confirm: (url) async {
          prompts++;
          return ClipboardLinkDecision.dismiss;
        },
        open: (url) async {},
        readSnapshot: () async =>
            _snapshot('https://archiveofourown.org/works/12345'),
      );
      await controller.check();
      expect(prompts, 0);
      controller.dispose();
    });

    test('offers the canonical link when the setting is on', () async {
      Ao3Config.saveClipboardPrompt(true);
      String? confirmed;
      String? opened;
      final controller = ClipboardLinkController(
        canPrompt: () => true,
        confirm: (url) async {
          confirmed = url;
          return ClipboardLinkDecision.open;
        },
        open: (url) async {
          opened = url;
        },
        readSnapshot: () async => _snapshot(
            'look at this https://archiveofourown.org/works/12345/chapters/9'),
      );
      await controller.check();
      expect(confirmed, 'https://archiveofourown.org/works/12345');
      expect(opened, 'https://archiveofourown.org/works/12345');
      controller.dispose();
    });

    test('a dismissed link is not offered twice', () async {
      Ao3Config.saveClipboardPrompt(true);
      var prompts = 0;
      final controller = ClipboardLinkController(
        canPrompt: () => true,
        confirm: (url) async {
          prompts++;
          return ClipboardLinkDecision.dismiss;
        },
        open: (url) async {},
        readSnapshot: () async =>
            _snapshot('https://archiveofourown.org/works/4242'),
      );
      await controller.check();
      await controller.check();
      expect(prompts, 1);
      controller.dispose();
    });
  });
}
