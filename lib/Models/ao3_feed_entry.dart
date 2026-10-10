import 'dart:convert';

/// One row of an AO3 works listing: the summary card the site shows for a
/// work. Enough to decide whether to open it, without fetching the work.
class Ao3FeedEntry {
  const Ao3FeedEntry({
    required this.workId,
    required this.title,
    required this.author,
    required this.updatedAtMs,
    this.summaryText = '',
    this.words,
    this.chapters = '',
    this.rating = '',
    this.warnings = '',
    this.category = '',
    this.completion = '',
    this.fandoms = const [],
    this.tags = const [],
  });

  final int workId;
  final String title;
  final String author;
  final int updatedAtMs;
  final String summaryText;
  final int? words;
  final String chapters;
  final String rating;
  final String warnings;
  final String category;
  final String completion;
  final List<String> fandoms;
  final List<String> tags;

  Ao3FeedEntry copyWith({
    int? workId,
    String? title,
    String? author,
    int? updatedAtMs,
    String? summaryText,
    int? words,
    String? chapters,
    String? rating,
    String? warnings,
    String? category,
    String? completion,
    List<String>? fandoms,
    List<String>? tags,
  }) {
    return Ao3FeedEntry(
      workId: workId ?? this.workId,
      title: title ?? this.title,
      author: author ?? this.author,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      summaryText: summaryText ?? this.summaryText,
      words: words ?? this.words,
      chapters: chapters ?? this.chapters,
      rating: rating ?? this.rating,
      warnings: warnings ?? this.warnings,
      category: category ?? this.category,
      completion: completion ?? this.completion,
      fandoms: fandoms ?? this.fandoms,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'workId': workId,
        'title': title,
        'author': author,
        'updatedAtMs': updatedAtMs,
        'summaryText': summaryText,
        'words': words,
        'chapters': chapters,
        'rating': rating,
        'warnings': warnings,
        'category': category,
        'completion': completion,
        'fandoms': fandoms,
        'tags': tags,
      };

  factory Ao3FeedEntry.fromJson(Map<String, dynamic> json) {
    return Ao3FeedEntry(
      workId: json['workId'] as int,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      updatedAtMs: json['updatedAtMs'] as int? ?? 0,
      summaryText: json['summaryText'] as String? ?? '',
      words: json['words'] as int?,
      chapters: json['chapters'] as String? ?? '',
      rating: json['rating'] as String? ?? '',
      warnings: json['warnings'] as String? ?? '',
      category: json['category'] as String? ?? '',
      completion: json['completion'] as String? ?? '',
      fandoms: (json['fandoms'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory Ao3FeedEntry.decode(String raw) =>
      Ao3FeedEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static List<Ao3FeedEntry> listFromJson(List<dynamic> raw) =>
      raw.map((e) => Ao3FeedEntry.fromJson(e as Map<String, dynamic>)).toList();

  static List<dynamic> listToJson(List<Ao3FeedEntry> entries) =>
      entries.map((e) => e.toJson()).toList();
}
