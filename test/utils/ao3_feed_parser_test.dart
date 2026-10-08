import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/ao3_feed_parser.dart';

const String listing = '''
<ol class="work index group">
<li id="work_94234971" class="work blurb group work-94234971 user-29637516" role="article">
<div class="header module">
<!-- updated_at=1791485054 -->
<h4 class="heading">
<a href="/works/94234971">Let us become one</a>
by
<a rel="author" href="/users/LadyCasera/pseuds/LadyCasera">LadyCasera</a>
</h4>
<h5 class="fandoms heading">
<span class="landmark">Fandoms:</span>
<a class="tag" href="/tags/Malcolm%20in%20the%20Middle/works">Malcolm in the Middle</a>
</h5>
<ul class="required-tags">
<li><span class="rating-explicit rating" title="Explicit"><span class="text">Explicit</span></span></li>
<li><span class="warning-yes warnings" title="Underage Sex"><span class="text">Underage Sex</span></span></li>
<li><span class="category-slash category" title="M/M"><span class="text">M/M</span></span></li>
<li><span class="complete-yes iswip" title="Complete Work"><span class="text">Complete Work</span></span></li>
</ul>
<p class="datetime">08 Oct 2026</p>
</div>
<ul class="tags commas">
<li class='warnings'><a class="tag" href="/tags/Underage%20Sex/works">Underage Sex</a></li>
<li class='relationships'><a class="tag" href="/tags/Malcolm*s*Reese/works">Malcolm/Reese</a></li>
<li class='freeforms'><a class="tag" href="/tags/Hurt*s*Comfort/works">Hurt/Comfort</a></li>
</ul>
<h6 class="landmark heading">Summary</h6>
<blockquote class="userstuff summary">
<p>Malcolm ist komplett
verrueckt   nach seinem Auto.</p>
</blockquote>
<dl class="stats">
<dt class="language">Language:</dt><dd class="language" lang="de">Deutsch</dd>
<dt class="words">Words:</dt><dd class="words">4,835</dd>
<dt class="chapters">Chapters:</dt><dd class="chapters">1/1</dd>
</dl>
</li>
<li id="work_94234972" class="work blurb group" role="article">
<div class="header module">
<h4 class="heading"><a href="/works/94234972">Second work</a>
by <a rel="author" href="/users/anon/pseuds/anon">Anonymous</a></h4>
<p class="datetime">02 Jan 2026</p>
</div>
<dl class="stats"><dt class="words">Words:</dt><dd class="words">12</dd>
<dt class="chapters">Chapters:</dt><dd class="chapters">3/?</dd></dl>
</li>
<li class="work blurb group" role="article">
<div class="header module"><h4 class="heading"><a href="/works/0">no id</a></h4></div>
</li>
</ol>
''';

void main() {
  group('Ao3FeedParser.parseList', () {
    final entries = Ao3FeedParser.parseList(listing);

    test('parses one entry per work blurb, skipping broken rows', () {
      expect(entries, hasLength(2));
      expect(entries[0].workId, 94234971);
      expect(entries[1].workId, 94234972);
    });

    test('reads title, author and the embedded update epoch', () {
      expect(entries[0].title, 'Let us become one');
      expect(entries[0].author, 'LadyCasera');
      expect(entries[0].updatedAtMs, 1791485054 * 1000);
    });

    test('falls back to the displayed date when the epoch is missing', () {
      expect(entries[1].updatedAtMs,
          DateTime.utc(2026, 1, 2).millisecondsSinceEpoch);
    });

    test('reads required tags, fandom, tags and collapsed summary', () {
      expect(entries[0].rating, 'Explicit');
      expect(entries[0].warnings, 'Underage Sex');
      expect(entries[0].category, 'M/M');
      expect(entries[0].completion, 'Complete Work');
      expect(entries[0].fandoms, ['Malcolm in the Middle']);
      expect(entries[0].tags, containsAll(['Hurt/Comfort', 'Underage Sex']));
      expect(entries[0].summaryText,
          'Malcolm ist komplett verrueckt nach seinem Auto.');
      expect(entries[0].words, 4835);
      expect(entries[0].chapters, '1/1');
    });

    test('parses a sparse blurb without summary or tags', () {
      expect(entries[1].title, 'Second work');
      expect(entries[1].author, 'Anonymous');
      expect(entries[1].summaryText, isEmpty);
      expect(entries[1].tags, isEmpty);
      expect(entries[1].words, 12);
      expect(entries[1].chapters, '3/?');
    });
  });

  group('Ao3FeedParser.isAdultGate', () {
    test('detects the adult content gate', () {
      const gate = '<p>This work could have adult content. </p>';
      expect(Ao3FeedParser.isAdultGate(gate), isTrue);
    });

    test('does not flag a real listing', () {
      expect(Ao3FeedParser.isAdultGate(listing), isFalse);
    });
  });
}
