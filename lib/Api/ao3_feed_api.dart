import '../Models/ao3_feed_entry.dart';
import '../Utils/ao3_config.dart';
import '../Utils/ao3_feed_parser.dart';
import 'ao3_api.dart';

/// Reads AO3 works listings: a tag's works page (the home feed) and the
/// works search (the search screen). Both render the same blurb markup, so
/// [Ao3FeedParser] serves both.
abstract final class Ao3FeedApi {
  static const int pageSize = 20;

  static Uri tagWorksUri(String tag, {int page = 1}) {
    return Uri.parse(
      'https://archiveofourown.org/tags/' +
          Uri.encodeComponent(tag.trim()) +
          '/works',
    ).replace(queryParameters: {
      'view_adult': 'true',
      if (page > 1) 'page': page.toString(),
    });
  }

  static Uri searchWorksUri(String query, {int page = 1}) {
    return Uri.parse('https://archiveofourown.org/works/search')
        .replace(queryParameters: {
      'view_adult': 'true',
      'page': page.toString(),
      'work_search[query]': query,
      'work_search[sort_id]': '_score',
    });
  }

  /// Latest works under [tag]. A missing tag surfaces as
  /// [Ao3Failure.notFound] (AO3 answers 404), so the add-tag flow can react.
  static Future<List<Ao3FeedEntry>> fetchTagWorks(
    String tag, {
    int page = 1,
    Ao3Fetcher? fetcher,
    Ao3Config? config,
  }) {
    return _list(
      tagWorksUri(tag, page: page),
      fetcher: fetcher,
      config: config,
    );
  }

  /// Full-text search. AO3 keeps this endpoint slow (tens of seconds); the
  /// UI must set that expectation instead of hiding it.
  static Future<List<Ao3FeedEntry>> searchWorks(
    String query, {
    int page = 1,
    Ao3Fetcher? fetcher,
    Ao3Config? config,
  }) {
    return _list(
      searchWorksUri(query, page: page),
      fetcher: fetcher,
      config: config,
    );
  }

  static Future<List<Ao3FeedEntry>> _list(
    Uri uri, {
    Ao3Fetcher? fetcher,
    Ao3Config? config,
  }) async {
    final settings = config ?? Ao3Config.load();
    if (!settings.enabled) {
      throw const Ao3Exception(Ao3Failure.disabled);
    }
    final doFetch = fetcher ?? Ao3Api.defaultFetcher(settings);
    final result = await doFetch(uri);
    if (Ao3FeedParser.isAdultGate(result.body)) {
      throw const Ao3Exception(Ao3Failure.blocked);
    }
    return Ao3FeedParser.parseList(result.body);
  }
}
