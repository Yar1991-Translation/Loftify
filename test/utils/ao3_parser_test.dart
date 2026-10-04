import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/ao3_parser.dart';

/// Fixture markup mirrors a real `/downloads/{id}/Work.html` export
/// (captured 2026-10-02): a `#preface` header, a `#chapters` body of
/// repeating `div.meta.group` / `div.userstuff` / `div#endnotesN`, and an
/// `#afterword` boilerplate block.
const _multiChapterExport = r'''
<html><head><title>Unquenchable - threerings | Archive of Our Own</title></head>
<body>
<div id="preface">
  <h2 class="toc-heading">Preface</h2>
  <p class="message"><b>Unquenchable</b><br /><a href="https://archiveofourown.org/works/12345">Archive of Our Own</a></p>
  <div class="meta">
    <dl class="tags">
      <dt>Rating:</dt><dd><a href="/tags/Explicit">Explicit</a></dd>
      <dt>Archive Warning:</dt><dd><a href="/tags/No+Archive+Warnings+Apply">No Archive Warnings Apply</a></dd>
      <dt>Fandom:</dt><dd><a href="/tags/Harry+Potter">Harry Potter - J. K. Rowling</a></dd>
      <dt>Relationship:</dt><dd><a href="/tags/Severus+Snape%2FHermione+Granger">Severus Snape/Hermione Granger</a></dd>
      <dt>Additional Tags:</dt><dd><a href="/tags/Romance">Romance</a>, <a href="/tags/Angst">Angst</a></dd>
      <dt>Language:</dt><dd>English</dd>
      <dt>Stats:</dt><dd>Published: 2004-08-01 Words: 1,980 Chapters: 2/2</dd>
    </dl>
    <h1>Unquenchable</h1>
    <div class="byline">by <a href="/users/threerings">threerings</a></div>
    <p>Summary</p>
    <blockquote class="userstuff"><p>Hermione and Snape argue about potions.</p></blockquote>
    <p>Notes</p>
    <blockquote class="userstuff"><p>Beta read by someone.</p></blockquote>
  </div>
</div>
<div id="chapters" class="userstuff">
  <div class="meta group">
    <h2 class="heading">Chapter 1: The Potions Lab</h2>
    <div class="notes"><p>See the end of the chapter for notes.</p></div>
  </div>
  <div class="userstuff"><p>Hermione looked around the Potions lab.</p><script>bad()</script></div>
  <div id="endnotes1" class="meta"><p>Chapter one end notes.</p></div>
  <div class="meta group">
    <h2 class="heading">Chapter 2: Aftermath</h2>
  </div>
  <div class="userstuff"><p>They never spoke of it again.</p></div>
</div>
<div id="afterword">
  <h2 class="toc-heading">Afterword</h2>
  <p class="message">Please drop by the Archive and comment.</p>
</div>
</body></html>
''';

const _singleChapterExport = r'''
<html><body>
<div id="preface">
  <p class="message"><b>Solo Fic</b></p>
  <div class="meta">
    <dl class="tags">
      <dt>Rating:</dt><dd><a href="/tags/General">General Audiences</a></dd>
      <dt>Stats:</dt><dd>Published: 2020-01-02 Words: 300 Chapters: 1/1</dd>
    </dl>
    <h1>Solo Fic</h1>
    <div class="byline">by <a href="/users/writer">writer</a></div>
  </div>
</div>
<div id="chapters" class="userstuff">
  <h2 class="toc-heading">Solo Fic</h2>
  <div class="userstuff"><p>Only chapter body.</p></div>
</div>
<div id="afterword"><p class="message">Thanks for reading.</p></div>
</body></html>
''';

void main() {
  group('Ao3Parser', () {
    test('reads the work header', () {
      final work = Ao3Parser.parse(_multiChapterExport, workId: 12345)!;
      expect(work.id, 12345);
      expect(work.title, 'Unquenchable');
      expect(work.author, 'threerings');
      expect(work.authorUrl, '/users/threerings');
      expect(work.rating, 'Explicit');
      expect(work.warnings, ['No Archive Warnings Apply']);
      expect(work.fandoms, ['Harry Potter - J. K. Rowling']);
      expect(work.relationships, ['Severus Snape/Hermione Granger']);
      expect(work.additionalTags, ['Romance', 'Angst']);
      expect(work.language, 'English');
      expect(work.publishedAt, '2004-08-01');
      expect(work.words, 1980);
      expect(work.chaptersStat, '2/2');
      expect(work.summaryHtml, contains('argue about potions'));
      // Language and Stats are structured fields, not chips.
      expect(work.tagGroups.map((g) => g.label),
          isNot(contains(anyOf('Language', 'Stats'))));
      expect(work.notesHtml, contains('Beta read'));
      expect(work.sourceUrl, 'https://archiveofourown.org/works/12345');
    });

    test('splits chapters, notes and end notes', () {
      final work = Ao3Parser.parse(_multiChapterExport, workId: 12345)!;
      expect(work.chapters, hasLength(2));
      expect(work.isMultiChapter, isTrue);

      final first = work.chapters.first;
      expect(first.index, 1);
      expect(first.title, 'The Potions Lab');
      expect(first.bodyHtml, contains('Potions lab'));
      expect(first.notesHtml, contains('See the end of the chapter'));
      expect(first.endNotesHtml, contains('Chapter one end notes'));

      final second = work.chapters[1];
      expect(second.index, 2);
      expect(second.title, 'Aftermath');
      expect(second.bodyHtml, contains('never spoke of it again'));
    });

    test('drops script tags from chapter bodies', () {
      final work = Ao3Parser.parse(_multiChapterExport, workId: 12345)!;
      expect(work.chapters.first.bodyHtml, isNot(contains('bad()')));
      expect(work.chapters.first.bodyHtml, isNot(contains('<script')));
    });

    test('single chapter export falls back to the work title', () {
      final work = Ao3Parser.parse(_singleChapterExport, workId: 777)!;
      expect(work.chapters, hasLength(1));
      expect(work.isMultiChapter, isFalse);
      expect(work.chapters.single.title, 'Solo Fic');
      expect(work.chapters.single.bodyHtml, contains('Only chapter body'));
      expect(work.rating, 'General Audiences');
      expect(work.words, 300);
    });

    test('returns null for a non-work page', () {
      const blockPage = '<html><head><title>Shields are up! | Archive of Our Own'
          '</title></head><body><h1>Shields are up!</h1></body></html>';
      expect(Ao3Parser.parse(blockPage, workId: 1), isNull);
      expect(Ao3Parser.parse('', workId: 1), isNull);
    });

    test('unknown labels still render and never throw', () {
      const localized = r'''
<html><body>
<div id="preface">
  <div class="meta">
    <dl class="tags">
      <dt>分级:</dt><dd><a href="/tags/Mature">Mature</a></dd>
      <dt>Stats:</dt><dd>Words: 12</dd>
    </dl>
    <h1>标题</h1>
  </div>
</div>
<div id="chapters" class="userstuff">
  <div class="userstuff"><p>正文</p></div>
</div>
</body></html>
''';
      final work = Ao3Parser.parse(localized, workId: 9)!;
      expect(work.rating, isEmpty);
      expect(work.tagGroups.single.label, '分级');
      expect(work.tagGroups.single.values, ['Mature']);
      expect(work.words, 12);
      expect(work.chapters.single.bodyHtml, contains('正文'));
    });
  });
}
