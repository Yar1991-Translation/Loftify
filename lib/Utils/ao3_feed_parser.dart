import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../Models/ao3_feed_entry.dart';

/// Parses AO3 works listings (a tag's works page or a search result page).
/// Both share the same `li.work.blurb` markup, so one parser serves the home
/// feed and the search screen.
abstract final class Ao3FeedParser {
  /// Extracts every work blurb, newest first as the site orders them.
  static List<Ao3FeedEntry> parseList(String rawHtml) {
    final document = html_parser.parse(rawHtml);
    final blurbs = document.querySelectorAll('li.work.blurb');
    final entries = <Ao3FeedEntry>[];
    for (final blurb in blurbs) {
      final entry = _parseBlurb(blurb);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  /// True when the page is the adult-content gate instead of a listing.
  static bool isAdultGate(String rawHtml) {
    return rawHtml.contains('This work could have adult content') &&
        !rawHtml.contains('li class="work blurb');
  }

  static Ao3FeedEntry? _parseBlurb(Element blurb) {
    final id = int.tryParse(
      (blurb.id.startsWith('work_') ? blurb.id.substring(5) : blurb.id),
    );
    if (id == null || id <= 0) return null;

    final heading = blurb.querySelector('div.header h4.heading');
    final titleLink = heading?.querySelector('a[href^="/works/"]');
    final title = (titleLink?.text ?? '').trim();
    final author = (heading
                ?.querySelector('a[rel="author"]')
                ?.text ??
            '')
        .trim();

    final updatedAtMs = _parseUpdatedAt(blurb);
    final datetime = (blurb.querySelector('p.datetime')?.text ?? '').trim();

    final requiredTags =
        blurb.querySelectorAll('ul.required-tags span.text');
    String pick(int index) =>
        index < requiredTags.length ? requiredTags[index].text.trim() : '';

    final fandoms = blurb
        .querySelectorAll('h5.fandoms a.tag')
        .map((node) => node.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final tags = <String>[];
    for (final node in blurb.querySelectorAll('ul.tags.commas li a.tag')) {
      final text = node.text.trim();
      if (text.isNotEmpty) tags.add(text);
    }

    final summaryText = _collapse(
      blurb.querySelector('blockquote.userstuff.summary')?.text ?? '',
    );

    String stat(String className) =>
        (blurb.querySelector('dl.stats dd.$className')?.text ?? '').trim();

    return Ao3FeedEntry(
      workId: id,
      title: title,
      author: author,
      updatedAtMs: updatedAtMs ?? _parseDisplayDate(datetime),
      summaryText: summaryText,
      words: int.tryParse((stat('words')).replaceAll(',', '')),
      chapters: stat('chapters'),
      rating: pick(0),
      warnings: pick(1),
      category: pick(2),
      completion: pick(3),
      fandoms: fandoms,
      tags: tags.take(8).toList(),
    );
  }

  /// The listing embeds the exact update epoch in a comment, which beats
  /// parsing the displayed "08 Oct 2026".
  static int? _parseUpdatedAt(Element blurb) {
    final comment = RegExp(r'updated_at=(\d+)');
    final html = blurb.innerHtml;
    if (html.isEmpty) return null;
    final match = comment.firstMatch(html);
    if (match == null) return null;
    final seconds = int.tryParse(match.group(1) ?? '');
    if (seconds == null || seconds <= 0) return null;
    return seconds * 1000;
  }

  static int _parseDisplayDate(String text) {
    final match = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})').firstMatch(text);
    if (match == null) return 0;
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final month = months[match.group(2)];
    final day = int.tryParse(match.group(1) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    if (month == null || day == null || year == null) return 0;
    return DateTime.utc(year, month, day).millisecondsSinceEpoch;
  }

  static String _collapse(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
