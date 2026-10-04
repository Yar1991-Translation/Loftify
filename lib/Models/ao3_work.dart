/// Parsed shape of an AO3 work.
///
/// The export markup at `/downloads/{id}/Work.html` differs from the live
/// site, so the HTML itself is handled by `Ao3Parser`; these types only carry
/// the parsed result and know how to round-trip through Hive.
class Ao3TagGroup {
  const Ao3TagGroup({required this.label, required this.values});

  final String label;
  final List<String> values;

  Map<String, dynamic> toJson() => {
        'label': label,
        'values': values,
      };

  factory Ao3TagGroup.fromJson(Map<String, dynamic> json) => Ao3TagGroup(
        label: json['label']?.toString() ?? '',
        values: (json['values'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class Ao3Chapter {
  const Ao3Chapter({
    required this.index,
    required this.title,
    required this.bodyHtml,
    this.notesHtml = '',
    this.endNotesHtml = '',
  });

  /// 1-based position in the work.
  final int index;
  final String title;
  final String bodyHtml;
  final String notesHtml;
  final String endNotesHtml;

  bool get hasContent => bodyHtml.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'bodyHtml': bodyHtml,
        'notesHtml': notesHtml,
        'endNotesHtml': endNotesHtml,
      };

  factory Ao3Chapter.fromJson(Map<String, dynamic> json) => Ao3Chapter(
        index: json['index'] as int? ?? 1,
        title: json['title']?.toString() ?? '',
        bodyHtml: json['bodyHtml']?.toString() ?? '',
        notesHtml: json['notesHtml']?.toString() ?? '',
        endNotesHtml: json['endNotesHtml']?.toString() ?? '',
      );
}

class Ao3Work {
  const Ao3Work({
    required this.id,
    required this.title,
    this.author = '',
    this.authorUrl = '',
    this.summaryHtml = '',
    this.notesHtml = '',
    this.tagGroups = const [],
    this.chapters = const [],
    this.language = '',
    this.publishedAt = '',
    this.words,
    this.chaptersStat = '',
    this.fetchedAtMs = 0,
  });

  final int id;
  final String title;
  final String author;
  final String authorUrl;
  final String summaryHtml;
  final String notesHtml;

  /// Every `<dt>/<dd>` pair from the work header, in page order. Labels are
  /// kept verbatim so a localized header still renders correctly.
  final List<Ao3TagGroup> tagGroups;
  final List<Ao3Chapter> chapters;
  final String language;
  final String publishedAt;
  final int? words;

  /// Raw "1/1" or "3/?" chapter counter as published.
  final String chaptersStat;

  /// Milliseconds since epoch when this copy was fetched; drives the LRU.
  final int fetchedAtMs;

  String get sourceUrl => 'https://archiveofourown.org/works/' + id.toString();

  bool get isMultiChapter => chapters.length > 1;

  /// First value of the group whose label starts with [prefix]
  /// (case-insensitive, ignoring the trailing colon).
  String? tagValue(String prefix) {
    final values = tagValues(prefix);
    return values.isEmpty ? null : values.first;
  }

  List<String> tagValues(String prefix) {
    final needle = prefix.toLowerCase();
    for (final group in tagGroups) {
      final label = group.label.toLowerCase().replaceAll(':', '').trim();
      if (label == needle) return group.values;
    }
    return const [];
  }

  String get rating => tagValue('rating') ?? '';
  List<String> get warnings => tagValues('archive warning');
  List<String> get fandoms => tagValues('fandom');
  List<String> get relationships => tagValues('relationship');
  List<String> get characters => tagValues('characters');
  List<String> get additionalTags => tagValues('additional tags');

  Ao3Work copyWith({int? fetchedAtMs}) => Ao3Work(
        id: id,
        title: title,
        author: author,
        authorUrl: authorUrl,
        summaryHtml: summaryHtml,
        notesHtml: notesHtml,
        tagGroups: tagGroups,
        chapters: chapters,
        language: language,
        publishedAt: publishedAt,
        words: words,
        chaptersStat: chaptersStat,
        fetchedAtMs: fetchedAtMs ?? this.fetchedAtMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'authorUrl': authorUrl,
        'summaryHtml': summaryHtml,
        'notesHtml': notesHtml,
        'tagGroups': tagGroups.map((e) => e.toJson()).toList(),
        'chapters': chapters.map((e) => e.toJson()).toList(),
        'language': language,
        'publishedAt': publishedAt,
        'words': words,
        'chaptersStat': chaptersStat,
        'fetchedAtMs': fetchedAtMs,
      };

  factory Ao3Work.fromJson(Map<String, dynamic> json) => Ao3Work(
        id: json['id'] as int? ?? 0,
        title: json['title']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        authorUrl: json['authorUrl']?.toString() ?? '',
        summaryHtml: json['summaryHtml']?.toString() ?? '',
        notesHtml: json['notesHtml']?.toString() ?? '',
        tagGroups: (json['tagGroups'] as List? ?? const [])
            .map((e) => Ao3TagGroup.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        chapters: (json['chapters'] as List? ?? const [])
            .map((e) => Ao3Chapter.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        language: json['language']?.toString() ?? '',
        publishedAt: json['publishedAt']?.toString() ?? '',
        words: json['words'] as int?,
        chaptersStat: json['chaptersStat']?.toString() ?? '',
        fetchedAtMs: json['fetchedAtMs'] as int? ?? 0,
      );
}
