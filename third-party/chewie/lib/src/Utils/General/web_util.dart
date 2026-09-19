import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

class FaviconRequest {
  final String url;
  final List<String>? articleUrls;

  FaviconRequest(this.url, {this.articleUrls});

  Map<String, dynamic> toMap() => {
        'url': url,
        'articleUrls': articleUrls,
      };

  static FaviconRequest fromMap(Map<String, dynamic> map) => FaviconRequest(
        map['url'],
        articleUrls: List<String>.from(map['articleUrls'] ?? []),
      );
}

class WebUtil {
  static Uri getBaseUrl(dynamic url) {
    Uri uri;

    if (url is String) {
      uri = Uri.tryParse(url) ?? Uri();
    } else if (url is Uri) {
      uri = url;
    } else {
      return Uri();
    }

    final scheme = uri.scheme;
    final host = uri.host;
    // Callers pass an empty string when no source page is known. Interpolating
    // the empty scheme/host below used to build the literal "://" and
    // Uri.parse threw "Invalid empty scheme" for every image rendered without
    // a source url.
    if (scheme.isEmpty || host.isEmpty) {
      return Uri();
    }
    final port = uri.hasPort ? ':${uri.port}' : '';

    return Uri.parse('$scheme://$host$port');
  }

  static bool isHashOnlyLink(String value) {
    return value.startsWith('#') && !value.contains(RegExp(r'[:\/\\]'));
  }

  /// Repairs URLs whose scheme was stripped by the source but whose scheme
  /// separator survived (LOFTER rich-text content emits `src="://img..."`).
  /// `Uri.parse` throws "Invalid empty scheme" on those, which used to blow
  /// up image rendering with a red error box.
  static String normalizeSchemelessUrl(String url) {
    if (url.startsWith('://')) {
      return 'https$url';
    }
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    return url;
  }

  static final RegExp _schemelessUrlAttrRegex = RegExp(
    r'''((?:src|href|data-src|data-original|data-srcset|data-url|poster|srcset|action)\s*=\s*)(["']?)\s*://''',
    caseSensitive: false,
  );
  static final RegExp _schemelessCssUrlRegex = RegExp(
    r'''(url\(\s*)(["']?)\s*://''',
    caseSensitive: false,
  );

  /// Repairs every scheme-less attribute/CSS url in a content HTML string so
  /// no downstream parser (fwfh, NetworkImage, CachedNetworkImage) can hit an
  /// "Invalid empty scheme" FormatException mid-build.
  static String sanitizeSchemelessHtml(String html) {
    final attrsFixed = html.replaceAllMapped(
      _schemelessUrlAttrRegex,
      (match) => '${match[1]}${match[2]}https://',
    );
    return attrsFixed.replaceAllMapped(
      _schemelessCssUrlRegex,
      (match) => '${match[1]}${match[2]}https://',
    );
  }

  static String resolveRelativeUrl(String baseUrl, String imageUrl) {
    imageUrl = normalizeSchemelessUrl(imageUrl);
    try {
      if (imageUrl.isEmpty) {
        return imageUrl;
      }
      final uri = Uri.parse(imageUrl);
      if (uri.hasScheme) {
        return imageUrl;
      }
      if (isHashOnlyLink(imageUrl)) {
        return imageUrl;
      }

      final base = Uri.parse(baseUrl);
      final resolved = base.resolveUri(uri);
      return resolved.toString();
    } catch (e) {
      return imageUrl;
    }
  }

  static final _urlRegex = RegExp(
    r"^https?://(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,63}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*$)",
    caseSensitive: false,
  );

  static bool isUrl(String url) => _urlRegex.hasMatch(url.trim());

  static Uri getRootDomainWithScheme(String url) {
    Uri uri = Uri.parse(url);
    return Uri.parse(
        "${uri.scheme}://${uri.host.split('.').reversed.take(2).toList().reversed.join('.')}");
  }

  static Future<String?> fetchFaviconCompute(FaviconRequest req) async {
    return await WebUtil.fetchFavicon(
      req.url,
      articleUrls: req.articleUrls ?? [],
    );
  }

  static Future<String?> fetchFavicon(
    String originUrl, {
    List<String> articleUrls = const [],
  }) async {
    try {
      for (final articleUrl in articleUrls) {
        var favicon = await fetchFavicon(articleUrl);
        if (favicon != null) return favicon;
      }

      final Uri originUri = Uri.parse(originUrl);
      final Uri baseUri = getBaseUrl(originUrl);

      var response = await http.get(originUri);
      if (response.statusCode == 200) {
        final dom = parse(response.body);
        final faviconUrl =
            _extractFaviconFromDom(dom, baseUri.toString(), baseUri.scheme);

        if (faviconUrl != null && await validateFavicon(faviconUrl)) {
          return faviconUrl;
        }
      }

      response = await http.get(baseUri);
      if (response.statusCode == 200) {
        final dom = parse(response.body);
        final faviconUrl =
            _extractFaviconFromDom(dom, baseUri.toString(), baseUri.scheme);

        if (faviconUrl != null && await validateFavicon(faviconUrl)) {
          return faviconUrl;
        }
      }

      final fallback = baseUri.resolve('/favicon.ico').toString();
      if (await validateFavicon(fallback)) {
        return fallback;
      }

    } catch (e) {
      return null;
    }
    return null;
  }

  static String? _extractFaviconFromDom(
      dom.Document dom, String baseUrl, String scheme) {
    final links = dom.getElementsByTagName("link");

    for (final link in links) {
      final rel = (link.attributes["rel"] ?? "").toLowerCase();
      final href = link.attributes["href"];

      if (href != null &&
          (rel.contains("icon") ||
              rel.contains("shortcut icon") ||
              rel.contains("apple-touch-icon"))) {
        return _resolveFaviconUrl(href, baseUrl, scheme);
      }
    }
    return null;
  }

  static String _resolveFaviconUrl(String href, String baseUrl, String scheme) {
    if (href.startsWith('//')) return '$scheme:$href';
    if (href.startsWith('/')) return '$baseUrl$href';
    if (href.startsWith('http')) return href;
    return '$baseUrl/$href';
  }

  static Future<bool> validateFavicon(String url) async {
    try {
      final result = await http.get(Uri.parse(url));
      if (result.statusCode == 200) {
        final contentType = result.headers["content-type"]?.toLowerCase();
        return contentType != null && contentType.startsWith("image");
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
