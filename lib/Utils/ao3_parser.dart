import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../Models/ao3_work.dart';

/// Turns an AO3 work export into [Ao3Work].
///
/// The export (`/downloads/{id}/Work.html`) is a stripped page: a
/// `#preface` header, a `#chapters` body of repeating
/// `div.meta.group` + `div.userstuff` (+ `div#endnotesN`), and an
/// `#afterword` boilerplate block. Everything here is defensive: AO3 markup
/// changes and localized headers must degrade to a partial work rather than
/// throw.
abstract final class Ao3Parser {
  /// Tags whose content is never useful in a reader.
  static const _dropped = {'script', 'style', 'iframe', 'object', 'form'};

  /// Returns null when [rawHtml] is not a work export — e.g. a login redirect
  /// or the "Shields are up!" block page. Callers use that to classify errors.
  static Ao3Work? parse(String rawHtml, {required int workId}) {
    if (rawHtml.trim().isEmpty) return null;
    final Document document;
    try {
      document = html_parser.parse(rawHtml);
    } catch (_) {
      return null;
    }
    final preface = document.querySelector('#preface');
    final chapterRoot = document.querySelector('#chapters');
    if (preface == null || chapterRoot == null) return null;

    final documentTitle = _text(document.querySelector('title'))
        .replaceAll(' | Archive of Our Own', '')
        .trim();
    final title = _firstNonEmpty([
      _text(preface.querySelector('h1')),
      _text(preface.querySelector('p.message b')),
      documentTitle,
    ]);
    if (title.isEmpty && chapterRoot.children.isEmpty) return null;

    final byline = preface.querySelector('.byline');
    final authorLink = byline?.querySelector('a') ?? preface.querySelector('a[rel=author]');
    final chapters = _parseChapters(chapterRoot, fallbackTitle: title);
    // A truncated or unexpected payload can yield a header with no readable
    // chapter at all. Returning null surfaces the actionable "could not read
    // this page" state instead of a reader with an empty body.
    if (chapters.isEmpty) return null;

    return Ao3Work(
      id: workId,
      title: title,
      author: _text(authorLink),
      authorUrl: _href(authorLink),
      summaryHtml: _blockAfterLabel(preface, 'Summary'),
      notesHtml: _blockAfterLabel(preface, 'Notes'),
      tagGroups: _parseTagGroups(preface.querySelector('dl.tags')),
      chapters: chapters,
      language: _tagValue(preface, 'Language'),
      publishedAt: _statsValue(preface, 'Published'),
      words: _statsNumber(preface, 'Words'),
      chaptersStat: _statsValue(preface, 'Chapters'),
      fetchedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Rows that are surfaced as structured fields instead of chips.
  static const _nonTagLabels = {'stats', 'language'};

  /// `dl.tags` is a flat `dt`/`dd` sequence; keep the page order and the
  /// verbatim labels so a non-English header still renders.
  static List<Ao3TagGroup> _parseTagGroups(Element? list) {
    if (list == null) return const [];
    final groups = <Ao3TagGroup>[];
    String? label;
    for (final child in list.children) {
      final tag = child.localName;
      if (tag == 'dt') {
        label = child.text.trim().replaceAll(RegExp(r':\s*$'), '');
      } else if (tag == 'dd') {
        final current = label;
        if (current == null || current.isEmpty) continue;
        if (_nonTagLabels.contains(current.toLowerCase())) continue;
        final links = child.querySelectorAll('a');
        final values = links.isNotEmpty
            ? links.map((a) => a.text.trim()).where((v) => v.isNotEmpty).toList()
            : child.text
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList();
        if (values.isEmpty) continue;
        groups.add(Ao3TagGroup(label: current, values: values));
      }
    }
    return groups;
  }

  /// The summary and notes sit in a `<p>Summary</p><blockquote>…` pair.
  static String _blockAfterLabel(Element preface, String label) {
    final needle = label.toLowerCase();
    for (final node in preface.querySelectorAll('p, h3')) {
      if (node.text.trim().toLowerCase() != needle) continue;
      var sibling = node.nextElementSibling;
      while (sibling != null) {
        if (sibling.localName == 'blockquote' || sibling.localName == 'div') {
          return _clean(sibling.innerHtml);
        }
        break;
      }
    }
    return '';
  }

  static List<Ao3Chapter> _parseChapters(Element root,
      {required String fallbackTitle}) {
    final chapters = <Ao3Chapter>[];
    String? pendingHeading;

    void startChapter(String heading) {
      chapters.add(Ao3Chapter(
        index: chapters.length + 1,
        title: _chapterTitle(heading, chapters.length + 1, fallbackTitle),
        bodyHtml: '',
      ));
    }

    void replaceLast(Ao3Chapter chapter) {
      chapters[chapters.length - 1] = chapter;
    }

    for (final child in root.children) {
      final element = child;
      final id = element.id;
      final classes = element.classes;

      if (classes.contains('toc-heading') || classes.contains('heading')) {
        // Single-chapter exports put the chapter title in a toc-heading.
        pendingHeading = element.text.trim();
        continue;
      }
      if (classes.contains('meta') && classes.contains('group')) {
        final heading = _text(element.querySelector('h2, h3'));
        startChapter(
            heading.isEmpty ? (pendingHeading ?? '') : heading);
        final notes = element.querySelector('.notes, blockquote');
        if (notes != null) {
          final body = _clean(notes.innerHtml);
          if (body.isNotEmpty) {
            final last = chapters.last;
            replaceLast(Ao3Chapter(
              index: last.index,
              title: last.title,
              bodyHtml: last.bodyHtml,
              notesHtml: body,
              endNotesHtml: last.endNotesHtml,
            ));
          }
        }
        pendingHeading = null;
        continue;
      }
      if (id.startsWith('endnotes')) {
        if (chapters.isEmpty) continue;
        final last = chapters.last;
        replaceLast(Ao3Chapter(
          index: last.index,
          title: last.title,
          bodyHtml: last.bodyHtml,
          notesHtml: last.notesHtml,
          endNotesHtml: _clean(element.innerHtml),
        ));
        continue;
      }
      if (classes.contains('userstuff')) {
        final body = _clean(element.innerHtml);
        if (body.isEmpty) continue;
        if (chapters.isEmpty) {
          startChapter(pendingHeading ?? '');
        }
        final last = chapters.last;
        replaceLast(Ao3Chapter(
          index: last.index,
          title: last.title,
          bodyHtml: last.bodyHtml.isEmpty ? body : last.bodyHtml + body,
          notesHtml: last.notesHtml,
          endNotesHtml: last.endNotesHtml,
        ));
        pendingHeading = null;
        continue;
      }
    }

    // A work whose body never matched the expected containers still has a
    // usable title; return one empty chapter so the reader can say so.
    if (chapters.isEmpty) {
      final raw = _clean(root.innerHtml);
      if (raw.isEmpty) return const [];
      chapters.add(Ao3Chapter(
        index: 1,
        title: fallbackTitle,
        bodyHtml: raw,
      ));
    }
    return chapters;
  }

  /// "Chapter 3: Title" -> "Title"; plain "Title" is kept as-is.
  static String _chapterTitle(
      String heading, int index, String fallbackTitle) {
    var title = heading.trim();
    final match =
        RegExp(r'^Chapter\s+\d+\s*[:：]\s*(.*)$', caseSensitive: false)
            .firstMatch(title);
    if (match != null) title = match.group(1)?.trim() ?? '';
    if (title.isEmpty) return fallbackTitle;
    return title;
  }

  static String _tagValue(Element preface, String label) {
    final list = preface.querySelector('dl.tags');
    if (list == null) return '';
    String? current;
    for (final child in list.children) {
      if (child.localName == 'dt') {
        current = child.text.trim().replaceAll(RegExp(r':\s*$'), '');
      } else if (child.localName == 'dd') {
        if (current?.toLowerCase() == label.toLowerCase()) {
          return child.text.trim();
        }
      }
    }
    return '';
  }

  /// The Stats row is a single `dd` like
  /// "Published: 2004-08-01 Words: 1,980 Chapters: 1/1".
  static String _statsValue(Element preface, String key) {
    final stats = _statsRow(preface);
    if (stats == null) return '';
    final match = RegExp(
      key + r':\s*([^\n]+?)(?=\s+[A-Z][a-z]+:|$)',
    ).firstMatch(stats);
    return match?.group(1)?.trim() ?? '';
  }

  static int? _statsNumber(Element preface, String key) {
    final raw = _statsValue(preface, key).replaceAll(',', '');
    return int.tryParse(RegExp(r'\d+').firstMatch(raw)?.group(0) ?? '');
  }

  static String? _statsRow(Element preface) {
    final list = preface.querySelector('dl.tags');
    if (list == null) return null;
    String? current;
    for (final child in list.children) {
      if (child.localName == 'dt') {
        current = child.text.trim().replaceAll(RegExp(r':\s*$'), '');
      } else if (child.localName == 'dd' &&
          current?.toLowerCase() == 'stats') {
        return child.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }
    return null;
  }

  /// Strips containers the reader never renders; keeps inline markup so
  /// `flutter_widget_from_html` can still style emphasis, links and images.
  static String _clean(String html) {
    if (html.trim().isEmpty) return '';
    final DocumentFragment fragment;
    try {
      fragment = html_parser.parseFragment(html);
    } catch (_) {
      return html;
    }
    for (final node in fragment.querySelectorAll(_dropped.join(','))) {
      node.remove();
    }
    final text = fragment.text ?? '';
    return text.trim().isEmpty && fragment.children.isEmpty
        ? ''
        : _innerHtml(fragment);
  }

  static String _innerHtml(DocumentFragment fragment) {
    final buffer = StringBuffer();
    for (final node in fragment.nodes) {
      buffer.write(node is Element ? node.outerHtml : node.text ?? '');
    }
    return buffer.toString().trim();
  }

  static String _text(Element? element) =>
      element == null ? '' : element.text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _href(Element? element) => element?.attributes['href'] ?? '';

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}
