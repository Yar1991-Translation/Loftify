import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dev builds must be told when the matching stable release lands: the
/// comparison used to parse "0-dev" with int.parse, throw, and fall back to a
/// string compare that called the prerelease newer.
void main() {
  group('ChewieUtils.compareVersion', () {
    test('a release outranks its own prerelease', () {
      expect(ChewieUtils.compareVersion('2.7.0', '2.7.0-dev.2'), greaterThan(0));
      expect(ChewieUtils.compareVersion('2.7.0-dev.2', '2.7.0'), lessThan(0));
      expect(ChewieUtils.compareVersion('v2.7.0', '2.7.0-dev.2'), greaterThan(0));
      expect(
        ChewieUtils.compareVersion('2.7.0-dev.2', '2.7.0-dev.1'),
        greaterThan(0),
      );
    });

    test('plain versions keep comparing by number', () {
      expect(ChewieUtils.compareVersion('2.7.0', '2.6.3'), greaterThan(0));
      expect(ChewieUtils.compareVersion('2.6.3', '2.7.0'), lessThan(0));
      expect(ChewieUtils.compareVersion('2.7.0', '2.7.0'), 0);
      expect(ChewieUtils.compareVersion('v2.6.3', '2.6.3'), 0);
      expect(ChewieUtils.compareVersion('2.7', '2.7.0'), 0);
      expect(ChewieUtils.compareVersion('2.10.0', '2.9.9'), greaterThan(0));
    });

    test('a dev build still sees the next stable', () {
      expect(ChewieUtils.compareVersion('2.7.1', '2.7.0-dev.2'), greaterThan(0));
      expect(ChewieUtils.compareVersion('2.8.0', '2.7.0-dev.2'), greaterThan(0));
    });

    test('build metadata and stray text do not throw', () {
      expect(ChewieUtils.compareVersion('2.7.0+2700', '2.7.0'), 0);
      expect(ChewieUtils.compareVersion('2.7.0+build', '2.7.0-dev.1'),
          greaterThan(0));
      expect(ChewieUtils.compareVersion('', '2.7.0'), isNot(0));
    });
  });
}
