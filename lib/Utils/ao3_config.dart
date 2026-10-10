import 'package:awesome_chewie/awesome_chewie.dart';

import 'hive_util.dart';

/// User settings for the AO3 reader.
///
/// [proxy] is not cosmetic: AO3 is unreachable on some networks without one,
/// and Dart's `HttpClient` never picks up the system proxy that the WebView
/// fallback inherits for free.
class Ao3Config {
  const Ao3Config({
    this.enabled = true,
    this.proxy = '',
    this.clipboardPrompt = false,
    this.cacheLimit = defaultCacheLimit,
    this.fontScale = 1.0,
  });

  static const int defaultCacheLimit = 50;

  final bool enabled;

  /// `host:port` of an HTTP proxy, empty for a direct connection.
  final String proxy;

  /// Whether copying an AO3 link offers to open it. Off by default so the
  /// clipboard prompt does not fire on every copied link.
  final bool clipboardPrompt;

  /// How many works stay cached offline (LRU beyond this).
  final int cacheLimit;

  /// Reader text scale, 1.0 = 100%.
  final double fontScale;

  bool get needsProxy => proxy.trim().isNotEmpty;

  static Ao3Config load() => Ao3Config(
        enabled: ChewieHiveUtil.getBool(HiveUtil.ao3EnabledKey),
        proxy: ChewieHiveUtil.getString(HiveUtil.ao3ProxyKey) ?? '',
        clipboardPrompt:
            ChewieHiveUtil.getBool(HiveUtil.ao3ClipboardKey, defaultValue: false),
        cacheLimit: ChewieHiveUtil.getInt(HiveUtil.ao3CacheLimitKey,
            defaultValue: defaultCacheLimit),
        fontScale:
            ChewieHiveUtil.getInt(HiveUtil.ao3FontScaleKey, defaultValue: 100) /
                100,
      );

  static void saveProxy(String proxy) =>
      ChewieHiveUtil.put(HiveUtil.ao3ProxyKey, proxy.trim());

  static void saveEnabled(bool enabled) =>
      ChewieHiveUtil.put(HiveUtil.ao3EnabledKey, enabled);

  static void saveClipboardPrompt(bool enabled) =>
      ChewieHiveUtil.put(HiveUtil.ao3ClipboardKey, enabled);

  static void saveCacheLimit(int limit) =>
      ChewieHiveUtil.put(HiveUtil.ao3CacheLimitKey, limit);

  static void saveFontScale(double scale) => ChewieHiveUtil.put(
      HiveUtil.ao3FontScaleKey, (scale * 100).round());

  /// Accepts "host:port", "http://host:port" or "socks5://host:port" and
  /// returns the `PROXY host:port` string Dart expects, or null when unusable.
  static String? findProxyValue(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    final scheme = RegExp(r'^([a-zA-Z0-9]+)://').firstMatch(value);
    if (scheme != null) {
      final protocol = scheme.group(1)!.toUpperCase();
      value = value.substring(scheme.end);
      if (value.isEmpty) return null;
      if (protocol.startsWith('SOCKS')) return 'SOCKS5 ' + value;
    }
    return 'PROXY ' + value;
  }
}
